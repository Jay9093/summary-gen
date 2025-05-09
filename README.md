# Document Summary Generator

A Flask application that generates summaries from uploaded documents (PDF and TXT files) and stores them in AWS S3.

## Build Status
- Last tested: May 9, 2025
- Environment: Jenkins Pipeline
- Branch: master
- Status: Testing webhook integration

## Features

- Upload PDF and TXT files
- Extract text from documents
- Generate simple summaries
- Store files in AWS S3
- Modern, responsive UI
- CI/CD pipeline with Jenkins
- Infrastructure as Code with Terraform

## Prerequisites

- Python 3.13+
- AWS Account 
- Jenkins server
- Terraform
- SSH key pair

## Local Development Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/Jay9093/summary-gen.git
   cd summary-gen
   ```

2. Create and activate a virtual environment:
   ```bash
   python3 -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

4. Create a `.env` file:
   ```
   AWS_ACCESS_KEY_ID=your_access_key
   AWS_SECRET_ACCESS_KEY=your_secret_key
   AWS_REGION=us-east-1
   AWS_S3_BUCKET=your-bucket-name
   ```

5. Run the application:
   ```bash
   python app/app.py
   ```

## Infrastructure Setup

1. Configure AWS credentials:
   ```bash
   aws configure
   ```

2. Initialize Terraform:
   ```bash
   cd terraform
   terraform init
   ```

3. Review the plan:
   ```bash
   terraform plan
   ```

4. Apply the configuration:
   ```bash
   terraform apply
   ```

## Jenkins Pipeline Setup

1. Create a new Jenkins pipeline job
2. Configure the pipeline to use the Jenkinsfile
3. Add AWS credentials to Jenkins credentials store
4. Configure the GitHub webhook for automatic builds

## Project Structure

```
.
├── app/
│   ├── static/
│   │   └── styles.css
│   ├── templates/
│   │   └── index.html
│   └── app.py
├── tests/
│   └── test_app.py
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   └── user-data.sh
├── Jenkinsfile
├── requirements.txt
└── README.md
```

## Testing

Run the test suite:
```bash
pytest tests/ --cov=app
```

## Deployment

The application is automatically deployed when changes are pushed to the main branch. The Jenkins pipeline:

1. Runs tests
2. Plans Terraform changes
3. Applies infrastructure changes
4. Deploys the application to EC2
5. Updates environment variables

## Security

- S3 bucket is private
- EC2 security group restricts access
- IAM roles follow least privilege principle
- HTTPS enabled for production

## Monitoring

- AWS CloudWatch for logs and metrics
- EC2 status checks
- Jenkins build status

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

MIT License

## Automated Deployment
This project uses automated deployment with:
- Jenkins Pipeline
- Docker containerization
- AWS infrastructure
- GitHub webhook integration

Last updated: $(date) 
