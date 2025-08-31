pipeline {
    agent any
    
    environment {
        VM_IP = '172.188.114.181'        // Replace with your VM IP
        VM_USER = 'azureuser'
        DEPLOY_PATH = '/opt/flask-app'
    }
    
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/rk-madaka/cicd-demo.git'
            }
        }
        
        stage('Install Dependencies') {
            steps {
                sh 'python3 -m venv venv'
                sh '. venv/bin/activate && pip install -r requirements.txt'
                sh '. venv/bin/activate && pip install -r requirements-test.txt'
            }
        }
        
        stage('Run Tests') {
            steps {
                script {
                    try {
                        sh '. venv/bin/activate && python -m pytest tests/ -v'
                        currentBuild.result = 'SUCCESS'
                    } catch (Exception e) {
                        currentBuild.result = 'FAILURE'
                        error "Tests failed: ${e.getMessage()}"
                    }
                }
            }
            post {
                success {
                    echo 'All tests passed!'
                    slackSend channel: '#dev-notifications', 
                              color: 'good', 
                              message: "Tests PASSED: ${env.JOB_NAME} #${env.BUILD_NUMBER}"
                }
                failure {
                    echo 'Tests failed!'
                    slackSend channel: '#dev-notifications', 
                              color: 'danger', 
                              message: "Tests FAILED: ${env.JOB_NAME} #${env.BUILD_NUMBER}"
                }
            }
        }
        
        stage('Deploy to Azure VM') {
            when {
                expression { currentBuild.result == 'SUCCESS' }
            }
            steps {
                script {
                    echo "Deploying to Azure VM at ${env.VM_IP}"
                    
                    // Transfer files to VM (you'll need to set up SSH keys first)
                    sh """
                        rsync -avz -e "ssh -o StrictHostKeyChecking=no" \
                        --exclude='venv' \
                        --exclude='.git' \
                        ./ ${env.VM_USER}@${env.VM_IP}:${env.DEPLOY_PATH}/
                    """
                    
                    // Execute deployment script on remote VM
                    sh """
                        ssh -o StrictHostKeyChecking=no ${env.VM_USER}@${env.VM_IP} \
                        'cd ${env.DEPLOY_PATH} && chmod +x deploy.sh && ./deploy.sh'
                    """
                }
            }
        }
    }
}