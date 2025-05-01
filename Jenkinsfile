pipeline {
    // Define 'agent none' at the top as cleanWs runs before the docker agent starts
    agent none

    environment {
        DOCKER_IMAGE       = "ishhod08/pulsepoint"
        DOCKER_CREDENTIALS = "docker-hub-credentials"
        // Removed explicit TMPDIR setting to rely on the container/Node.js defaults
    }

    stages {
        stage('Clean Workspace on Host') {
            // This stage runs on any available agent or the controller if no agent is specified
            agent any
            steps {
                echo "Cleaning workspace on the Jenkins agent host..."
                // Use cleanWs BEFORE starting the docker container
                cleanWs()
            }
        }

        stage('Build, Package, and Deploy') {
            // This stage uses the Docker agent for all subsequent steps
            agent {
                docker {
                    image 'node:20-slim' // Using the stable LTS Alpine version
                    // IMPORTANT: Run as the same user ID/Group ID as the Jenkins user on the host (UID 111, GID 113 from your logs)
                    // This should fix the "script.sh.copy: not found" permission error
                    args '-u 111:113'

                    // Commented out the optional NPM cache mount for now
                    // args '-v $HOME/.npm:/root/.npm'
                }
            }
            steps {
                script {
                    echo "Running steps inside the Docker container as user 111:113..."

                    // --- Detailed Workspace Debugging Steps ---
                    // Corrected quoting for shell commands with '$' or '()'
                    // Using single quotes around the entire shell command string
                    sh 'echo "Current directory inside container: $(pwd)"'
                    sh 'echo "Listing contents of the workspace root:"'
                    sh 'ls -la /var/lib/jenkins/workspace/'
                    sh 'echo "Listing contents of the specific pipeline workspace:"'
                    sh 'ls -la /var/lib/jenkins/workspace/Pipeline-1'
                    sh 'echo "Listing contents of the @tmp directory (may not exist initially):"'
                    sh 'ls -la /var/lib/jenkins/workspace/Pipeline-1@tmp || true'
                    sh 'echo "Checking permissions on the pipeline workspace:"'
                    sh 'stat -c "%a %n" /var/lib/jenkins/workspace/Pipeline-1'
                    sh 'echo "Checking permissions on the @tmp directory (if it exists):"'
                    sh 'stat -c "%a %n" /var/lib/jenkins/workspace/Pipeline-1@tmp || true'
                    sh 'echo "PATH inside container: $PATH"'
                    sh 'echo "Checking if sh is found:"'
                    sh 'which sh || echo "sh not found in PATH"'
                    sh 'echo "--- End Detailed Workspace Debugging Steps ---"'

                    // Prepare Environment (now inside docker agent)
                    sh 'node --version'
                    sh 'npm --version'
                    sh 'df -h'

                    // Clone Repository (now inside docker agent - uses the workspace mounted by Jenkins)
                    echo "Cloning repository..."
                    checkout scm

                    // Clean Install & Build (now inside docker agent)
                    echo "Starting Clean Install & Build..."
                    // Use triple single quotes for multi-line script
                    sh '''#!/bin/bash
                    # Simplified cleanup with error handling - runs inside container
                    echo "Cleaning node_modules and package-lock.json..."
                    rm -rf node_modules package-lock.json || true
                    # npm cache clean --force || true # Generally not recommended unless cache is truly corrupt

                    # If you uncommented the npm cache mount above, you don't need this:
                    # mkdir -p .npm-cache
                    # export NPM_CONFIG_CACHE="./.npm-cache"

                    # Set NPM log level for more details if needed
                    export NPM_CONFIG_LOGLEVEL="verbose"

                    # Try npm ci first (faster and more reliable for CI)
                    echo "Installing dependencies with npm ci..."
                    npm ci || {
                        echo "npm ci failed, falling back to npm install..."
                        # Fall back to regular install if ci fails
                        # --no-audit and --prefer-offline can speed things up but adjust as needed
                        npm install --no-audit --prefer-offline
                    }

                    # Verify installation
                    if [ ! -d "node_modules" ]; then
                      echo "ERROR: Failed to install dependencies. node_modules directory not found."
                      exit 1
                    fi
                    echo "npm install/ci completed successfully."
                    '''

                    // Build Vue Application (now inside docker agent)
                    echo "Starting Vue application build..."
                    // Use triple single quotes for multi-line script
                    sh '''#!/bin/bash
                    # Build the Vue application
                    echo "Building Vue application..."
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

                    // Build Docker Image (now inside docker agent)
                    echo "Building Docker image..."
                    // The '.' assumes your Dockerfile is in the root of the workspace
                    docker.build("${DOCKER_IMAGE}:latest", '.')

                    // Login to Docker Hub (now inside docker agent)
                    echo "Logging in to Docker Hub..."
                    docker.withRegistry('https://registry-1.docker.io/v2/', DOCKER_CREDENTIALS) {
                          echo "🔐 Credential loaded for Docker Hub"
                          // Login happens automatically here
                    }
                     echo "Login successful."


                    // Push Image to Docker Hub (now inside docker agent)
                    echo "Pushing image to Docker Hub..."
                    docker.withRegistry('https://registry-1.docker.io/v2/', DOCKER_CREDENTIALS) {
                       docker.image("${DOCKER_IMAGE}:latest").push()
                    }
                    echo "Image push completed."

                } // End script block
            } // End steps
        } // End Build, Package, and Deploy stage

        stage('Deploy Container') {
             // This stage could potentially run on a different agent if deployment
             // targets a different host, or keep 'agent none' if deploying
             // from the Jenkins controller itself (less common).
             // For simplicity, let's assume it runs on a standard agent or controller with docker installed.
             agent any // Or agent { label 'your-deployment-agent' }
             steps {
                script {
                    echo "Starting container deployment..."
                    // These commands execute on the agent where this stage runs,
                    // NOT inside the node:20-alpine container.
                    // Ensure docker command is available on this agent.
                    sh 'echo "Pruning old docker images on deployment agent..."'
                    sh 'docker image prune -f'
                    sh 'echo "Stopping and removing old container..."'
                    // Using || true allows the pipeline to continue if stop/rm fails (e.g., container doesn't exist)
                    sh 'docker stop pulsepoint-container || true'
                    sh 'docker rm pulsepoint-container || true'
                    sh 'echo "Running new container..."'
                    sh "docker run -d --name pulsepoint-container -p 80:80 ${DOCKER_IMAGE}:latest"
                    sh 'echo "Deployment command executed."'
                    // You might want to add checks here to ensure the container started successfully
                    // sh 'docker ps -f name=pulsepoint-container'
                 } // End script block
             } // End steps
        } // End Deploy Container stage
    } // End stages

    post {
        success {
            echo '✅ Deployment Successful!'
        }
        failure {
            echo '❌ Deployment Failed.'
             // Optional: Add steps here to archive logs or send notifications on failure
        }
         // Optional: Another cleanWs here if you want to be extra sure, but usually not necessary
         // always {
         //     cleanWs()
         // }
    }
}