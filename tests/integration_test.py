import os
import boto3
import pytest
import requests
from botocore.exceptions import ClientError

def test_application_endpoint():
    """Test if the application is accessible"""
    response = requests.get('http://localhost:5001')
    assert response.status_code == 200
    assert 'Document Summary Generator' in response.text

def test_s3_bucket_access():
    """Test if S3 bucket is accessible and writable"""
    s3 = boto3.client('s3')
    bucket_name = os.getenv('S3_BUCKET_NAME')
    
    # Test bucket exists
    try:
        s3.head_bucket(Bucket=bucket_name)
    except ClientError as e:
        pytest.fail(f"S3 bucket {bucket_name} is not accessible: {str(e)}")
    
    # Test file upload
    test_content = b"Test content"
    test_key = "test/test.txt"
    
    try:
        s3.put_object(
            Bucket=bucket_name,
            Key=test_key,
            Body=test_content
        )
        
        # Verify file exists
        response = s3.get_object(Bucket=bucket_name, Key=test_key)
        assert response['Body'].read() == test_content
        
        # Clean up
        s3.delete_object(Bucket=bucket_name, Key=test_key)
    except ClientError as e:
        pytest.fail(f"Failed to interact with S3 bucket: {str(e)}")

def test_file_upload():
    """Test file upload functionality"""
    test_file = {
        'file': ('test.txt', b'Test content', 'text/plain')
    }
    
    response = requests.post('http://localhost:5001', files=test_file)
    assert response.status_code == 200
    assert 'Summary' in response.text

def test_pdf_processing():
    """Test PDF file processing"""
    # Create a simple PDF file
    pdf_content = b'%PDF-1.4\nTest PDF content'
    test_file = {
        'file': ('test.pdf', pdf_content, 'application/pdf')
    }
    
    response = requests.post('http://localhost:5001', files=test_file)
    assert response.status_code == 200
    assert 'Summary' in response.text

if __name__ == '__main__':
    pytest.main(['-v']) 