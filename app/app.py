from flask import Flask, render_template, request, flash, jsonify
import os
import boto3
from werkzeug.utils import secure_filename
from PyPDF2 import PdfReader
import io
import logging
from .config import UPLOAD_FOLDER, ALLOWED_EXTENSIONS, S3_BUCKET
from .summarizer import summarize_text

app = Flask(__name__)
app.secret_key = os.urandom(24)

# Configure max upload size (50MB)
app.config['MAX_CONTENT_LENGTH'] = 50 * 1024 * 1024

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Configure upload folder
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

# AWS Configuration
s3_client = boto3.client('s3')
BUCKET_NAME = S3_BUCKET

# Add health check endpoint
@app.route('/health')
def health_check():
    return {"status": "healthy", "version": "1.0.0"}, 200

# Add version endpoint
@app.route('/version')
def get_version():
    return jsonify({
        "version": "1.0.0",
        "last_updated": "2025-05-09",
        "environment": os.getenv('FLASK_ENV', 'development')
    })

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

def extract_text_from_pdf(file):
    try:
        pdf_reader = PdfReader(file)
        text = ""
        for page in pdf_reader.pages:
            text += page.extract_text() + "\n"
        return text
    except Exception as e:
        logger.error(f"Error extracting text from PDF: {str(e)}")
        return None

@app.route('/', methods=['GET', 'POST'])
def upload_file():
    summary = None
    if request.method == 'POST':
        if 'file' not in request.files:
            flash('No file part')
            return render_template('index.html')
        
        file = request.files['file']
        if file.filename == '':
            flash('No selected file')
            return render_template('index.html')
        
        if file and allowed_file(file.filename):
            filename = secure_filename(file.filename)
            filepath = os.path.join(app.config['UPLOAD_FOLDER'], filename)
            
            try:
                # Ensure upload directory exists
                os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)
                
                # Save the file
                file.save(filepath)
                logger.info(f"File saved to {filepath}")
                
                try:
                    # Extract text based on file type
                    if filename.endswith('.pdf'):
                        with open(filepath, 'rb') as pdf_file:
                            text = extract_text_from_pdf(pdf_file)
                    else:  # txt file
                        with open(filepath, 'r', encoding='utf-8') as txt_file:
                            text = txt_file.read()
                    
                    if text:
                        # Upload to S3
                        s3_client.upload_file(filepath, BUCKET_NAME, filename)
                        logger.info(f"File uploaded to S3 bucket {BUCKET_NAME}")
                        
                        # Generate summary using the summarizer module
                        summary = summarize_text(text)
                        logger.info("Summary generated successfully")
                        
                        # Clean up local file
                        os.remove(filepath)
                        logger.info(f"Temporary file {filepath} removed")
                        
                    else:
                        flash('Error processing file')
                except Exception as e:
                    logger.error(f"Processing error: {str(e)}")
                    flash(f'Error processing file: {str(e)}')
            except Exception as e:
                logger.error(f"File handling error: {str(e)}")
                flash(f'Error saving file: {str(e)}')
            
    return render_template('index.html', summary=summary)

if __name__ == '__main__':
    os.makedirs(UPLOAD_FOLDER, exist_ok=True)
    app.run(host='0.0.0.0', port=5001)
