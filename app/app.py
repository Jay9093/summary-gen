from flask import Flask, render_template, request, flash
import os
import boto3
from werkzeug.utils import secure_filename
from PyPDF2 import PdfReader
import io
import logging

app = Flask(__name__)
app.secret_key = os.urandom(24)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Configure upload folder
UPLOAD_FOLDER = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'uploads')
ALLOWED_EXTENSIONS = {'txt', 'pdf'}
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

# AWS Configuration
s3_client = boto3.client('s3')
BUCKET_NAME = os.getenv('S3_BUCKET', 'summary-gen-uploads')

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
                        
                        # Generate summary (simple version - first 500 characters)
                        summary = text[:500] + "..." if len(text) > 500 else text
                        
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
    app.run(host='0.0.0.0', port=5001, debug=True)
