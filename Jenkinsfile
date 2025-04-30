pipeline {
    agent {
        docker {
            image 'node:20'  // Uses official Node.js Docker image
        }
    }

    environment {
        DOCKER_IMAGE = "ishhod08/pulsepoint"
        DOCKER_CREDENTIALS = "docker-hub-credentials"
    }

    stages {
        stage('Clone Repository') {
            steps {
                git branch: 'main', url: 'https://github.com/Justinino1/PulsePoint.git'
            }
        }

        stage('Install Dependencies & Build') {
            steps {
                 // 1. Clean previous artifacts
                sh 'rm -rf node_modules package-lock.json'
                // 2. Clear npm cache
                sh 'npm cache clean --force'
                // 3. Fresh install using npm ci
                sh 'npm ci'
                // 4. Build your Vue app
                sh 'npm run build'  // creates the dist/ folder
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    docker.build("${DOCKER_IMAGE}:latest", '.')
                }
            }
        }

        stage('Login to Docker Hub') {
            steps {
                script {
                    docker.withRegistry('https://registry-1.docker.io/v2/', DOCKER_CREDENTIALS) {
                        echo "Logged in to Docker Hub"
                    }
                }
            }
        }

        stage('Push Image to Docker Hub') {
            steps {
                script {
                    docker.withRegistry('https://index.docker.io/v1/', DOCKER_CREDENTIALS) {
                        docker.image("${DOCKER_IMAGE}:latest").push()
                    }
                }
            }
        }

        stage('Deploy Container') {
            steps {
                script {
                    sh "docker image prune -f"
                    sh "docker stop vue-app-container || true"
                    sh "docker rm vue-app-container || true"
                    sh "docker run -d --name vue-app-container -p 80:80 ${DOCKER_IMAGE}:latest"
                }
            }
        }
    }

    post {
        success {
            echo 'Vue App Deployed Successfully!'
        }
        failure {
            echo 'Vue App Deployment Failed.'
        }
    }
}
