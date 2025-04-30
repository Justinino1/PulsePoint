pipeline {
    agent {
        docker {
            image 'node:22'          // Official Node LTS image
            // Running as root often helps with cleanWs and permissions inside the container
            args  '-u root:root'
        }
    }

    environment {
        DOCKER_IMAGE       = "ishhod08/pulsepoint"
        DOCKER_CREDENTIALS = "docker-hub-credentials" // Ensure this credential ID exists in Jenkins
    }

    stages {
        stage('Clean Workspace') {
            steps {
                cleanWs() // Clean the workspace before starting
            }
        }

        stage('Clone Repository') {
            steps {
                checkout scm        // uses the Jenkinsfile’s repo/branch
            }
        }

        // Removed the problematic 'Cleanup TMP' stage

        stage('Clean Install & Build') {
            steps {
                script {
                    // Clean previous installations forcefully
                    sh 'rm -rf node_modules package-lock.json'
                    // Specific cleanup for a potentially problematic module (optional, keep if needed)
                    sh 'rm -rf node_modules/execa node_modules/.execa-*'
                    // Clear npm cache forcefully
                    sh 'npm cache clean --force'
                    // Create a dedicated cache directory
                    sh 'mkdir -p .npm-cache'
                    // Ensure root owns the workspace contents inside the container for subsequent steps
                    sh 'chown -R root:root .'

                    // Install dependencies with retries
                    sh '''#!/bin/bash
                    for i in {1..3}; do
                      echo "Attempt $i: Installing dependencies"
                      # --legacy-peer-deps might be needed depending on npm/project versions
                      # --cache uses the dedicated cache directory
                      # --loglevel=verbose provides more detail on failures
                      npm install --legacy-peer-deps --cache .npm-cache --loglevel=verbose && break
                      echo "npm install failed. Retrying in 5s..."
                      sleep 5
                    done
                    # Check if installation was successful after loop
                    if [ ! -d "node_modules" ]; then
                      echo "Failed to install dependencies after 3 attempts."
                      exit 1
                    fi
                    '''
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    // Build the Docker image from the Dockerfile in the workspace root
                    docker.build("${DOCKER_IMAGE}:latest", '.')
                }
            }
        }

        stage('Login to Docker Hub') {
            steps {
                script {
                    // Authenticate with Docker Hub using defined credentials
                    // Using v2 endpoint is standard practice
                    docker.withRegistry('https://registry-1.docker.io/v2/', DOCKER_CREDENTIALS) {
                         // This echo runs after successful credential loading, not necessarily after login itself
                         // Docker login happens implicitly when withRegistry block is entered with credentials
                         echo "🔐 Credential loaded for Docker Hub"
                    }
                }
            }
        }

        stage('Push Image to Docker Hub') {
            steps {
                script {
                    // Re-authenticate within the push context and push the image
                    // Using v1 or v2 endpoint should work, stick to one if possible (v2 preferred)
                    docker.withRegistry('https://index.docker.io/v1/', DOCKER_CREDENTIALS) {
                       docker.image("${DOCKER_IMAGE}:latest").push()
                    }
                }
            }
        }

        stage('Deploy Container') {
            steps {
                script {
                    // Clean up old docker images to free space
                    sh 'docker image prune -f'
                    // Stop and remove the old container if it exists
                    sh 'docker stop pulsepoint-container || true' // || true prevents failure if container doesn't exist
                    sh 'docker rm pulsepoint-container || true'   // || true prevents failure if container doesn't exist
                    // Run the new container from the latest image
                    // -d: detached mode, --name: container name, -p 80:80: map host port 80 to container port 80
                    sh "docker run -d --name pulsepoint-container -p 80:80 ${DOCKER_IMAGE}:latest"
                }
            }
        }
    } // End of stages block

    post {
        always {
            // Clean the workspace after the build finishes, regardless of status
            cleanWs()
        }
        success {
            echo '✅ Deployment Successful!'
        }
        failure {
            echo '❌ Deployment Failed.'
        }
        // You could add other conditions like 'aborted', 'unstable' etc.
    }
} // End of pipeline block