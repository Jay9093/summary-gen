import pytest
from app.app import app
import os

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_index_page(client):
    response = client.get('/')
    assert response.status_code == 200
    assert b'Document Summary Generator' in response.data

def test_upload_no_file(client):
    response = client.post('/')
    assert response.status_code == 200
    assert b'No file part' in response.data

def test_upload_empty_file(client):
    response = client.post('/', data={'file': (None, '')})
    assert response.status_code == 200
    assert b'No selected file' in response.data

def test_upload_invalid_file(client):
    response = client.post('/', data={
        'file': (b'fake content', 'test.exe')
    })
    assert response.status_code == 200
    assert b'Error processing file' in response.data 