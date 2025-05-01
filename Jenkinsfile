pipeline {
    agent none

    environment {
        DOCKER_IMAGE       = "ishhod08/pulsepoint"
        DOCKER_CREDENTIALS = "docker-hub-credentials"
    }

    stages {
        stage('Clean Workspace') {
            agent any
            steps {
                echo "Cleaning workspace on the Jenkins agent host..."
                cleanWs()
            }
        }

        stage('Build and Package') {
            agent {
                docker {
                    image 'node:20-alpine'
                    // args can be added if needed
                }
            }
            steps {
                script {
                    echo "Checking out source code..."
                    checkout scm

                    echo "Node & npm version:"
                    sh 'node --version && npm --version'

                    echo "Cleaning previous installs..."
                    sh 'rm -rf node_modules package-lock.json || true'

                    echo "Installing dependencies..."
                    sh 'npm ci || npm install --no-audit --prefer-offline'

                    echo "Building Vue application..."
                    sh 'npm run build'

                    echo "Build output:"
                    sh 'ls -la dist'
                }
            }
        }

        stage('Docker Build & Push') {
            agent any
            steps {
                script {
                    echo "Building Docker image..."
                    sh 'ls -la' // Debug: show Dockerfile is present
                    def img = docker.build("${DOCKER_IMAGE}:latest", '.')

                    echo "Logging in and pushing to Docker Hub..."
                    docker.withRegistry('https://registry-1.docker.io/v2/', DOCKER_CREDENTIALS) {
                        img.push()
                    }
                }
            }
        }

        stage('Deploy Container') {
            agent any
            steps {
                script {
                    echo "Pruning old Docker images..."
                    sh 'docker image prune -f'

                    echo "Stopping and removing old container if exists..."
                    sh 'docker stop pulsepoint-container || true'
                    sh 'docker rm pulsepoint-container || true'

                    echo "Running new container..."
                    sh "docker run -d --name pulsepoint-container -p 80:80 ${DOCKER_IMAGE}:latest"

                    echo "Deployment complete. Checking running containers:"
                    sh 'docker ps -f name=pulsepoint-container'
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
            echo '✅ Deployment Successful!'
        }
        failure {
            echo '❌ Deployment Failed.'
        }
    }
}