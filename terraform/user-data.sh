#!/bin/bash

# Update system
apt-get update
apt-get upgrade -y

# Install dependencies
apt-get install -y python3-pip python3-venv nginx poppler-utils

# Create application directory
mkdir -p /home/ubuntu/app
cd /home/ubuntu/app

# Clone repository
git clone ${github_repo} .

# Create and activate virtual environment
python3 -m venv venv
source venv/bin/activate

# Install Python dependencies
pip install --upgrade pip
pip install -r requirements.txt

# Create environment file
cat > .env << EOL
AWS_S3_BUCKET=${s3_bucket_name}
EOL

# Configure Nginx
cat > /etc/nginx/sites-available/${app_name} << EOL
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

# Enable Nginx site
ln -sf /etc/nginx/sites-available/${app_name} /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
systemctl restart nginx

# Create systemd service
cat > /etc/systemd/system/${app_name}.service << EOL
[Unit]
Description=${app_name} Flask Application
After=network.target

[Service]
User=ubuntu
WorkingDirectory=/home/ubuntu/app
Environment="PATH=/home/ubuntu/app/venv/bin"
ExecStart=/home/ubuntu/app/venv/bin/gunicorn --workers 3 --bind 127.0.0.1:5001 app.app:app

[Install]
WantedBy=multi-user.target
EOL

# Start and enable service
systemctl daemon-reload
systemctl start ${app_name}
systemctl enable ${app_name} 