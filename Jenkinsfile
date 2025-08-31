pipeline {
    agent any
    
    environment {
        VM_IP = '172.188.114.181'
        VM_USER = 'azureuser'
        DEPLOY_PATH = '/opt/flask-app'
        EMAIL_TO = 'rannjithkumar31@gmail.com'
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
        }
        
        stage('Deploy to Azure VM') {
            when {
                expression { currentBuild.result == 'SUCCESS' }
            }
            steps {
                script {
                    echo "Deploying to Azure VM at ${env.VM_IP}"
                    
                    sh """
                        rsync -avz -e "ssh -o StrictHostKeyChecking=no" \
                        --exclude='venv' \
                        --exclude='.git' \
                        ./ ${env.VM_USER}@${env.VM_IP}:${env.DEPLOY_PATH}/
                    """
                    
                    sh """
                        ssh -o StrictHostKeyChecking=no ${env.VM_USER}@${env.VM_IP} \
                        'cd ${env.DEPLOY_PATH} && chmod +x deploy.sh && ./deploy.sh'
                    """
                }
            }
        }
    }
    
    post {
        always {
            echo "Pipeline finished: ${currentBuild.result}"
        }
        success {
            mail to: env.EMAIL_TO,
                 subject: "SUCCESS: Pipeline ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                 body: "Build completed successfully.\n\nView details: ${env.BUILD_URL}"
        }
        failure {
            mail to: env.EMAIL_TO,
                 subject: "FAILED: Pipeline ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                 body: "Build failed. Please check Jenkins for details.\n\nView logs: ${env.BUILD_URL}"
        }
        unstable {
            mail to: env.EMAIL_TO,
                 subject: "UNSTABLE: Pipeline ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                 body: "Build is unstable. Some tests may have failed.\n\nView details: ${env.BUILD_URL}"
        }
    }
}