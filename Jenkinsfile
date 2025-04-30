pipeline {
    agent {
        docker {
            image 'node:20-alpine'   // More stable LTS version
            args  '-u root:root'
        }
    }

    environment {
        DOCKER_IMAGE       = "ishhod08/pulsepoint"
        DOCKER_CREDENTIALS = "docker-hub-credentials"
        TMPDIR             = "${WORKSPACE}/tmp"  // Explicitly set TMPDIR
    }

    stages {
        stage('Prepare Environment') {
            steps {
                // Create and set permissions for temporary directory
                sh 'mkdir -p ${TMPDIR}'
                sh 'chmod 777 ${TMPDIR}'
                
                // Diagnostic information
                sh 'node --version'
                sh 'npm --version'
                sh 'df -h'
            }
        }

        stage('Clean Workspace') {
            steps {
                cleanWs() // Clean the workspace before starting
            }
        }

        stage('Clone Repository') {
            steps {
                checkout scm
            }
        }

        stage('Clean Install & Build') {
            steps {
                script {
                    // Simplified cleanup with error handling
                    sh 'rm -rf node_modules package-lock.json || true'
                    sh 'npm cache clean --force || true'
                    
                    // Create a dedicated cache directory
                    sh 'mkdir -p .npm-cache'
                    
                    // Install dependencies with better practices
                    sh '''#!/bin/bash
                    # Set NPM configuration
                    export NPM_CONFIG_CACHE="./.npm-cache"
                    export NPM_CONFIG_LOGLEVEL="verbose"
                    
                    # Try npm ci first (faster and more reliable for CI)
                    echo "Installing dependencies with npm ci..."
                    npm ci || {
                        echo "npm ci failed, falling back to npm install..."
                        # Fall back to regular install if ci fails
                        npm install --no-audit --prefer-offline
                    }
                    
                    # Verify installation
                    if [ ! -d "node_modules" ]; then
                      echo "Failed to install dependencies."
                      exit 1
                    fi
                    '''
                }
            }
        }

        stage('Build Vue Application') {
            steps {
                script {
                    // Build the Vue application
                    sh '''#!/bin/bash
                    echo "Building Vue application..."
                    npm run build
                    
                    # Verify build output exists
                    if [ ! -d "dist" ]; then
                      echo "Build failed - no dist directory found."
                      exit 1
                    else
                      echo "Build succeeded. Contents of dist directory:"
                      ls -la dist
                    fi
                    '''
                }
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
                         echo "🔐 Credential loaded for Docker Hub"
                    }
                }
            }
        }

        stage('Push Image to Docker Hub') {
            steps {
                script {
                    docker.withRegistry('https://registry-1.docker.io/v2/', DOCKER_CREDENTIALS) {
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
                    sh 'docker stop pulsepoint-container || true'
                    sh 'docker rm pulsepoint-container || true'
                    sh "docker run -d --name pulsepoint-container -p 80:80 ${DOCKER_IMAGE}:latest"
                }
            }
        }
    }

    post {
        always {
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