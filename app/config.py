import os

# AWS configuration
AWS_REGION = "us-east-1"
S3_BUCKET = "summary-gen-uploads-xioh3mbg"
ALLOWED_EXTENSIONS = {'txt', 'pdf'}
UPLOAD_FOLDER = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'uploads')

os.makedirs(UPLOAD_FOLDER, exist_ok=True)
