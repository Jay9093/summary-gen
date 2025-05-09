from flask import Flask, request, render_template
import os
import boto3
from botocore.exceptions import ClientError
import textract
from summarizer import summarize_text
from werkzeug.utils import secure_filename
import config
import tempfile

app = Flask(__name__)
app.config['UPLOAD_FOLDER'] = config.UPLOAD_FOLDER

# AWS Configuration
S3_BUCKET = os.getenv('S3_BUCKET')
AWS_ACCESS_KEY = os.getenv('AWS_ACCESS_KEY')
AWS_SECRET_KEY = os.getenv('AWS_SECRET_KEY')
AWS_REGION = os.getenv('AWS_REGION', 'us-east-1')

# Initialize S3 client
s3_client = boto3.client(
    's3',
    aws_access_key_id=AWS_ACCESS_KEY,
    aws_secret_access_key=AWS_SECRET_KEY,
    region_name=AWS_REGION
)

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in config.ALLOWED_EXTENSIONS

def upload_to_s3(file_path, object_name=None):
    if object_name is None:
        object_name = os.path.basename(file_path)
    
    try:
        s3_client.upload_file(file_path, S3_BUCKET, object_name)
        return True
    except ClientError as e:
        print(f"Error uploading to S3: {e}")
        return False

@app.route('/', methods=['GET', 'POST'])
def upload_file():
    summary = None
    if request.method == 'POST':
        if 'file' not in request.files:
            return 'No file part'
        
        file = request.files['file']
        if file.filename == '':
            return 'No selected file'
        
        if file:
            # Create a temporary file
            with tempfile.NamedTemporaryFile(delete=False) as temp_file:
                file.save(temp_file.name)
                
                try:
                    # Extract text from the file
                    text = textract.process(temp_file.name).decode('utf-8')
                    
                    # Upload to S3
                    upload_to_s3(temp_file.name, file.filename)
                    
                    # Generate summary (you can replace this with your actual summary logic)
                    summary = f"File processed and uploaded to S3. Content length: {len(text)} characters"
                    
                except Exception as e:
                    summary = f"Error processing file: {str(e)}"
                finally:
                    # Clean up the temporary file
                    os.unlink(temp_file.name)
    
    return render_template('index.html', summary=summary)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001, debug=True)
