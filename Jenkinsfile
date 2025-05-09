pipeline {
    agent any

    tools {
        git 'Default'
    }

    environment {
        AWS_CREDENTIALS = credentials('aws-credentials')
        GIT_CREDENTIALS = credentials('git-credentials')
        PYTHON_VERSION = '3.13'
        VENV_NAME = 'venv'
        APP_NAME = 'summary-gen'
        DOCKER_REGISTRY = 'your-docker-registry'
    }

    options {
        skipDefaultCheckout(true)
        timestamps()
        ansiColor('xterm')
    }

    stages {
        stage('Debug Info') {
            steps {
                sh '''
                    echo "Workspace: ${WORKSPACE}"
                    echo "Python Version:"
                    python3 --version || echo "Python3 not found"
                    echo "Git Version:"
                    git --version || echo "Git not found"
                    echo "Docker Version:"
                    docker --version || echo "Docker not found"
                    echo "Current Directory Contents:"
                    ls -la
                '''
            }
        }

        stage('Clean Workspace') {
            steps {
                cleanWs()
            }
        }

        stage('Checkout') {
            steps {
                script {
                    try {
                        checkout([
                            $class: 'GitSCM',
                            branches: [[name: '*/master']],
                            extensions: [
                                [$class: 'CleanBeforeCheckout'],
                                [$class: 'CloneOption', depth: 1, noTags: false, reference: '', shallow: true]
                            ],
                            userRemoteConfigs: [[
                                credentialsId: 'git-credentials',
                                url: 'https://github.com/Jay9093/summary-gen.git'
                            ]]
                        ])
                    } catch (Exception e) {
                        error "Failed to checkout code: ${e.message}"
                    }
                }
            }
        }

        stage('Setup Python') {
            steps {
                script {
                    try {
                        sh '''
                            # Check if Python exists
                            which python3 || echo "Python3 not found"
                            
                            # Create and activate virtual environment
                            python3 -m venv ${VENV_NAME} || echo "Failed to create venv"
                            . ${VENV_NAME}/bin/activate
                            
                            # Upgrade pip and install requirements
                            pip install --upgrade pip
                            pip install -r requirements.txt
                            pip install pytest pytest-cov
                            
                            # Verify installations
                            pip list
                        '''
                    } catch (Exception e) {
                        error "Failed to setup Python environment: ${e.message}"
                    }
                }
            }
        }

        stage('Run Tests') {
            steps {
                script {
                    try {
                        sh '''
                            . ${VENV_NAME}/bin/activate
                            # Create test directories if they don't exist
                            mkdir -p test-results
                            
                            # Run tests with coverage
                            pytest tests/ --junitxml=test-results/junit.xml --cov=app --cov-report=xml --cov-report=html -v
                        '''
                    } catch (Exception e) {
                        error "Tests failed: ${e.message}"
                    }
                }
            }
            post {
                always {
                    junit allowEmptyResults: true, testResults: 'test-results/*.xml'
                    publishCoverage adapters: [coberturaAdapter('coverage.xml')]
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    try {
                        docker.withRegistry('https://index.docker.io/v1/', 'docker-credentials') {
                            def customImage = docker.build("${APP_NAME}:${BUILD_NUMBER}")
                            customImage.push()
                            customImage.push('latest')
                        }
                    } catch (Exception e) {
                        error "Failed to build/push Docker image: ${e.message}"
                    }
                }
            }
        }

        stage('Deploy to AWS') {
            steps {
                script {
                    try {
                        // Get AWS infrastructure details
                        def appServerIP = sh(
                            script: 'cd terraform && terraform output -raw app_server_ip',
                            returnStdout: true
                        ).trim()
                        
                        def s3BucketName = sh(
                            script: 'cd terraform && terraform output -raw s3_bucket_name',
                            returnStdout: true
                        ).trim()

                        echo "Deploying to EC2 IP: ${appServerIP}"
                        echo "Using S3 Bucket: ${s3BucketName}"

                        // Deploy application
                        sh """
                            ssh -o StrictHostKeyChecking=no ubuntu@${appServerIP} '
                                docker pull ${APP_NAME}:${BUILD_NUMBER}
                                docker stop ${APP_NAME} || true
                                docker rm ${APP_NAME} || true
                                docker run -d --name ${APP_NAME} \
                                    -p 5001:5001 \
                                    -e AWS_ACCESS_KEY_ID=${AWS_CREDENTIALS_USR} \
                                    -e AWS_SECRET_ACCESS_KEY=${AWS_CREDENTIALS_PSW} \
                                    -e S3_BUCKET=${s3BucketName} \
                                    ${APP_NAME}:${BUILD_NUMBER}
                            '
                        """
                    } catch (Exception e) {
                        error "Deployment failed: ${e.message}"
                    }
                }
            }
        }
    }

    post {
        always {
            echo 'Cleaning up workspace...'
            cleanWs()
        }
        success {
            echo 'Pipeline completed successfully!'
            emailext (
                subject: "Build Successful: ${currentBuild.fullDisplayName}",
                body: "Build completed successfully. Check the application at http://[EC2-IP]:5001",
                recipientProviders: [[$class: 'DevelopersRecipientProvider']]
            )
        }
        failure {
            echo 'Pipeline failed!'
            emailext (
                subject: "Build Failed: ${currentBuild.fullDisplayName}",
                body: "Build failed. Check console output at ${BUILD_URL}",
                recipientProviders: [[$class: 'DevelopersRecipientProvider']]
            )
        }
    }
} 