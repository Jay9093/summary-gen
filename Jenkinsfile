pipeline {
    agent any

    environment {
        AWS_CREDENTIALS = credentials('aws-credentials')
        GIT_CREDENTIALS = credentials('git-credentials')
        PYTHON_VERSION = '3.13'
        VENV_NAME = 'venv'
        APP_NAME = 'summary-gen'
        DOCKER_REGISTRY = 'your-docker-registry'  // Replace with your Docker Hub username
    }

    stages {
        stage('Checkout') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/main']],
                    userRemoteConfigs: [[
                        credentialsId: 'git-credentials',
                        url: 'https://github.com/Jay9093/summary-gen.git'
                    ]]
                ])
            }
        }

        stage('Build and Test') {
            steps {
                sh '''
                    python${PYTHON_VERSION} -m venv ${VENV_NAME}
                    . ${VENV_NAME}/bin/activate
                    pip install --upgrade pip
                    pip install -r requirements.txt
                    pip install pytest pytest-cov
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

        stage('Build Docker Image') {
            steps {
                script {
                    docker.withRegistry("https://${DOCKER_REGISTRY}", 'docker-credentials') {
                        def customImage = docker.build("${DOCKER_REGISTRY}/${APP_NAME}:${BUILD_NUMBER}")
                        customImage.push()
                        customImage.push('latest')
                    }
                }
            }
        }

        stage('Deploy to AWS') {
            steps {
                script {
                    // Get AWS infrastructure details from Terraform outputs
                    def appServerIP = sh(
                        script: 'cd terraform && terraform output -raw app_server_ip',
                        returnStdout: true
                    ).trim()
                    
                    def s3BucketName = sh(
                        script: 'cd terraform && terraform output -raw s3_bucket_name',
                        returnStdout: true
                    ).trim()

                    // Create deployment configuration
                    writeFile file: 'deploy.sh', text: """
                        #!/bin/bash
                        set -e
                        
                        # Pull latest Docker image
                        docker pull ${DOCKER_REGISTRY}/${APP_NAME}:${BUILD_NUMBER}
                        
                        # Stop and remove existing container if it exists
                        docker stop ${APP_NAME} || true
                        docker rm ${APP_NAME} || true
                        
                        # Run new container
                        docker run -d \\
                            --name ${APP_NAME} \\
                            -p 5001:5001 \\
                            -e AWS_ACCESS_KEY_ID=${AWS_CREDENTIALS_USR} \\
                            -e AWS_SECRET_ACCESS_KEY=${AWS_CREDENTIALS_PSW} \\
                            -e S3_BUCKET=${s3BucketName} \\
                            ${DOCKER_REGISTRY}/${APP_NAME}:${BUILD_NUMBER}
                    """

                    // Deploy to EC2
                    sh """
                        chmod +x deploy.sh
                        scp -o StrictHostKeyChecking=no deploy.sh ubuntu@${appServerIP}:/home/ubuntu/
                        ssh -o StrictHostKeyChecking=no ubuntu@${appServerIP} 'bash /home/ubuntu/deploy.sh'
                    """
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                script {
                    def appServerIP = sh(
                        script: 'cd terraform && terraform output -raw app_server_ip',
                        returnStdout: true
                    ).trim()

                    // Wait for application to be ready
                    sh """
                        for i in {1..12}; do
                            if curl -s http://${appServerIP}:5001/health; then
                                echo "Application is up and running!"
                                exit 0
                            fi
                            echo "Waiting for application to be ready..."
                            sleep 10
                        done
                        echo "Application failed to start within timeout"
                        exit 1
                    """
                }
            }
        }
    }

    post {
        success {
            emailext (
                subject: "Deployment Successful: ${currentBuild.fullDisplayName}",
                body: """
                    Deployment completed successfully!
                    Build: ${BUILD_NUMBER}
                    Check the application at: http://${sh(
                        script: 'cd terraform && terraform output -raw app_server_ip',
                        returnStdout: true
                    ).trim()}:5001
                """,
                recipientProviders: [[$class: 'DevelopersRecipientProvider']]
            )
        }
        failure {
            emailext (
                subject: "Deployment Failed: ${currentBuild.fullDisplayName}",
                body: "Check console output at ${env.BUILD_URL}",
                recipientProviders: [[$class: 'DevelopersRecipientProvider']]
            )
        }
        always {
            cleanWs()
        }
    }
} 