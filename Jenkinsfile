pipeline {
    agent any

    environment {
        AWS_CREDENTIALS = credentials('aws-credentials')
        GIT_CREDENTIALS = credentials('git-credentials')
        PYTHON_VERSION = '3.13'
        VENV_NAME = 'venv'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/main']],
                    userRemoteConfigs: [[
                        credentialsId: 'git-credentials',
                        url: 'https://github.com/your-username/summary-gen.git'
                    ]]
                ])
            }
        }

        stage('Setup Python Environment') {
            steps {
                sh '''
                    python${PYTHON_VERSION} -m venv ${VENV_NAME}
                    . ${VENV_NAME}/bin/activate
                    pip install --upgrade pip
                    pip install -r requirements.txt
                    pip install pytest pytest-cov
                '''
            }
        }

        stage('Run Tests') {
            steps {
                sh '''
                    . ${VENV_NAME}/bin/activate
                    pytest tests/ --cov=app --cov-report=xml
                '''
            }
            post {
                always {
                    junit 'test-results/*.xml'
                    cobertura coberturaReportFile: 'coverage.xml'
                }
            }
        }

        stage('Build and Push Docker Image') {
            steps {
                script {
                    docker.withRegistry('https://index.docker.io/v1/', 'docker-credentials') {
                        def customImage = docker.build("summary-gen:${BUILD_NUMBER}")
                        customImage.push()
                    }
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                dir('terraform') {
                    sh '''
                        terraform init
                        terraform plan -out=tfplan
                    '''
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                dir('terraform') {
                    sh 'terraform apply -auto-approve tfplan'
                }
            }
        }

        stage('Integration Tests') {
            steps {
                sh '''
                    . ${VENV_NAME}/bin/activate
                    python tests/integration_test.py
                '''
            }
        }

        stage('Deploy Application') {
            when {
                branch 'main'
            }
            steps {
                script {
                    def appServerIP = sh(
                        script: 'cd terraform && terraform output -raw app_server_ip',
                        returnStdout: true
                    ).trim()
                    
                    def s3BucketName = sh(
                        script: 'cd terraform && terraform output -raw s3_bucket_name',
                        returnStdout: true
                    ).trim()

                    sh '''
                        echo "Deploying to ${appServerIP}"
                        echo "S3 Bucket: ${s3BucketName}"
                        
                        # Create .env file with updated values
                        echo "AWS_S3_BUCKET=${s3BucketName}" > .env
                        
                        # Copy files to EC2 instance
                        scp -o StrictHostKeyChecking=no -r app/* ubuntu@${appServerIP}:/home/ubuntu/app/
                        scp -o StrictHostKeyChecking=no .env ubuntu@${appServerIP}:/home/ubuntu/app/
                        
                        # Restart the application
                        ssh -o StrictHostKeyChecking=no ubuntu@${appServerIP} "sudo systemctl restart ${app_name}"
                    '''
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
        success {
            emailext (
                subject: "Pipeline Successful: ${currentBuild.fullDisplayName}",
                body: "Check console output at ${env.BUILD_URL}",
                recipientProviders: [[$class: 'DevelopersRecipientProvider']]
            )
        }
        failure {
            emailext (
                subject: "Pipeline Failed: ${currentBuild.fullDisplayName}",
                body: "Check console output at ${env.BUILD_URL}",
                recipientProviders: [[$class: 'DevelopersRecipientProvider']]
            )
        }
    }
} 