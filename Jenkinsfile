pipeline {
    agent {
        docker {
            image 'node:22'           // Official Node LTS image
            args  '-u root:root'      // run as root so cleanWs can delete all files
        }
    }

    // ensure workspace is wiped *before* any checkout or build
    options {
        cleanWs()                    // Workspace Cleanup Plugin: nukes the entire workspace before checkout
    }

    environment {
        DOCKER_IMAGE       = "ishhod08/pulsepoint"
        DOCKER_CREDENTIALS = "docker-hub-credentials"
    }

    stages {
        stage('Clone Repository') {
            steps {
                checkout scm           // uses the Jenkinsfile’s repo/branch
            }
        }

       stage('Clean Install & Build') {
            steps {
                script {
                    // Fully remove any leftover modules
                    sh 'rm -rf node_modules package-lock.json'

                    // (Optional) Fix permissions in case of residual locks
                    sh 'find . -type d -name "node_modules" -exec chmod -R u+w {} + || true'

                    // Clean npm cache
                    sh 'npm cache clean --force'

                    // Clean install dependencies
                    sh 'npm ci'

                    // Build the app
                    sh 'npm run build'
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    // ensure your Dockerfile picks up the new dist/ folder
                    docker.build("${DOCKER_IMAGE}:latest", '.')
                }
            }
        }

        stage('Login to Docker Hub') {
            steps {
                script {
                    docker.withRegistry('https://registry-1.docker.io/v2/', DOCKER_CREDENTIALS) {
                        echo "🔐 Logged in to Docker Hub"
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
                    sh 'docker image prune -f'
                    sh 'docker stop pulsepoint-container || true'
                    sh 'docker rm pulsepoint-container || true'
                    sh "docker run -d --name pulsepoint-container -p 80:80 ${DOCKER_IMAGE}:latest"
                }
            }
        }
    }

    post {
        success {
            echo '✅ Deployment Successful!'
        }
        failure {
            echo '❌ Deployment Failed.'
        }
    }
}
