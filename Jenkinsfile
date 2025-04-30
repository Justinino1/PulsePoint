pipeline {
    agent {
        docker {
            image 'node:20'           // Official Node LTS image
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

        stage('Install Dependencies & Build') {
            steps {
                // double-safety: delete any stray files, clear cache, then do a clean install
                deleteDir()           // remove everything under workspace
                sh 'npm cache clean --force'
                sh 'npm ci'           // only installs exactly what's in package-lock.json
                sh 'npm run build'    // outputs production-ready files to dist/
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
