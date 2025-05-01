pipeline {
    // Define 'agent none' at the top as cleanWs runs before the docker agent starts
    agent none

    environment {
        DOCKER_IMAGE       = "ishhod08/pulsepoint"
        DOCKER_CREDENTIALS = "docker-hub-credentials"
    }

    stages {
        stage('Clean Workspace on Host') {
            agent any
            steps {
                echo "Cleaning workspace on the Jenkins agent host..."
                cleanWs()
            }
        }

        stage('Build, Package, and Deploy') {
            agent {
                docker {
                    image 'node:22' // Updated to match the version in Dockerfile (node:22)
                    args '-u 111:113' // Ensure the UID and GID match Jenkins user
                }
            }
            steps {
                script {
                    echo "Running steps inside the Docker container as user 111:113..."

                    // Debugging workspace contents
                    sh 'echo "Current directory inside container: $(pwd)"'
                    sh 'echo "Listing contents of the workspace root:"'
                    sh 'ls -la /var/lib/jenkins/workspace/'

                    // Clone Repository
                    echo "Cloning repository..."
                    checkout scm

                    // Prepare Environment (inside docker container)
                    sh 'node --version'
                    sh 'npm --version'
                    sh 'df -h'

                    // Clean Install & Build
                    echo "Starting Clean Install & Build..."
                    sh '''
                    # Set npm cache to writable location
                    export NPM_CONFIG_CACHE=/tmp/.npm
                    mkdir -p /tmp/.npm

                    # Clean the node_modules and package-lock.json before install
                    rm -rf node_modules package-lock.json || true

                    # Install dependencies using npm ci (or fallback to npm install if it fails)
                    npm ci || {
                        echo "npm ci failed, falling back to npm install..."
                        npm install --no-audit --prefer-offline
                    }

                    # Verify installation
                    if [ ! -d "node_modules" ]; then
                      echo "ERROR: Failed to install dependencies. node_modules directory not found."
                      exit 1
                    fi
                    echo "npm install/ci completed successfully."
                    '''

                    // Build Vue Application
                    echo "Starting Vue application build..."
                    sh '''
                    # Build the Vue application
                    npm run build

                    # Verify build output exists
                    if [ ! -d "dist" ]; then
                      echo "ERROR: Build failed - no dist directory found."
                      exit 1
                    else
                      echo "Build succeeded. Contents of dist directory:"
                      ls -la dist
                    fi
                    '''

                    // Build Docker Image
                    echo "Building Docker image..."
                    docker.build("${DOCKER_IMAGE}:latest", '.')

                    // Login to Docker Hub
                    echo "Logging in to Docker Hub..."
                    docker.withRegistry('https://registry-1.docker.io/v2/', DOCKER_CREDENTIALS) {
                        echo "🔐 Credential loaded for Docker Hub"
                    }
                    echo "Login successful."

                    // Push Image to Docker Hub
                    echo "Pushing image to Docker Hub..."
                    docker.withRegistry('https://registry-1.docker.io/v2/', DOCKER_CREDENTIALS) {
                        docker.image("${DOCKER_IMAGE}:latest").push()
                    }
                    echo "Image push completed."
                }
            }
        }

        stage('Deploy Container') {
            agent any
            steps {
                script {
                    echo "Starting container deployment..."
                    sh 'echo "Pruning old docker images on deployment agent..."'
                    sh 'docker image prune -f'
                    sh 'echo "Stopping and removing old container..."'
                    sh 'docker stop pulsepoint-container || true'
                    sh 'docker rm pulsepoint-container || true'
                    sh 'echo "Running new container..."'
                    sh "docker run -d --name pulsepoint-container -p 80:80 ${DOCKER_IMAGE}:latest"
                    sh 'echo "Deployment command executed."'
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
