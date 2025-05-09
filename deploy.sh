#!/bin/bash

# Update system and install dependencies
sudo apt-get update
sudo apt-get install -y python3-pip python3-venv nginx poppler-utils

# Create application directory
sudo mkdir -p /var/www/flask-app
sudo chown ubuntu:ubuntu /var/www/flask-app

# Clone repository (replace with your repository URL)
git clone https://github.com/yourusername/flask-app.git /var/www/flask-app

# Set up Python virtual environment
cd /var/www/flask-app
python3 -m venv venv
source venv/bin/activate

# Install Python dependencies
pip install -r requirements.txt

# Create environment file
cat > .env << EOL
S3_BUCKET=${S3_BUCKET}
AWS_ACCESS_KEY=${AWS_ACCESS_KEY}
AWS_SECRET_KEY=${AWS_SECRET_KEY}
AWS_REGION=${AWS_REGION}
EOL

# Set up Nginx
sudo tee /etc/nginx/sites-available/flask-app << EOL
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:5001;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOL

# Enable the site
sudo ln -s /etc/nginx/sites-available/flask-app /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx

# Set up systemd service
sudo tee /etc/systemd/system/flask-app.service << EOL
[Unit]
Description=Flask Application
After=network.target

[Service]
User=ubuntu
WorkingDirectory=/var/www/flask-app
Environment="PATH=/var/www/flask-app/venv/bin"
ExecStart=/var/www/flask-app/venv/bin/gunicorn --workers 3 --bind 127.0.0.1:5001 app.app:app

[Install]
WantedBy=multi-user.target
EOL

# Start the application
sudo systemctl start flask-app
sudo systemctl enable flask-app 