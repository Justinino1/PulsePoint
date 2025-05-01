pipeline {
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
                    image 'node:20-alpine'
                    // Keep this commented for now unless you resolve the permission issue
                    // args '-v $HOME/.npm:/root/.npm'
                }
            }
            steps {
                script {
                    echo "Running steps inside the Docker container..."

                    // --- Detailed Workspace Debugging Steps ---
                    sh 'echo "Current directory inside container: $(pwd)"'
                    sh 'echo "Listing contents of the workspace root:"'
                    sh 'ls -la /var/lib/jenkins/workspace/'
                    sh 'echo "Listing contents of the specific pipeline workspace:"'
                    sh 'ls -la /var/lib/jenkins/workspace/Pipeline-1'
                    sh 'echo "Listing contents of the @tmp directory (may not exist initially):"'
                    // Use '|| true' because the @tmp directory might not exist yet
                    sh 'ls -la /var/lib/jenkins/workspace/Pipeline-1@tmp || true'
                    sh 'echo "Checking permissions on the pipeline workspace:"'
                    sh 'stat -c "%a %n" /var/lib/jenkins/workspace/Pipeline-1'
                     sh 'echo "Checking permissions on the @tmp directory (if it exists):"'
                    sh 'stat -c "%a %n" /var/lib/jenkins/workspace/Pipeline-1@tmp || true'
                    sh 'echo "PATH inside container: $PATH"'
                    sh 'echo "Checking if sh is found:"' // Verify the shell interpreter itself
                    sh 'which sh || echo "sh not found in PATH"'
                    sh 'echo "--- End Detailed Workspace Debugging Steps ---"'

                    // ... rest of your stages (node --version, npm --version, checkout, etc.) remain the same ...

                    // Prepare Environment
                    sh 'node --version'
                    sh 'npm --version'
                    sh 'df -h'

                    // Clone Repository
                    echo "Cloning repository..."
                    checkout scm

                    // Clean Install & Build
                    echo "Starting Clean Install & Build..."
                     sh '''#!/bin/bash
                    # ... (your npm install/ci script here) ...
                    '''

                    // Build Vue Application
                    echo "Starting Vue application build..."
                    sh '''#!/bin/bash
                    # ... (your npm build script here) ...
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