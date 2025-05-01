pipeline {
    agent none // Agent is defined within stages

    environment {
        DOCKER_IMAGE      = "ishhod08/pulsepoint"
        DOCKER_CREDENTIALS = "docker-hub-credentials"
        // Remove or adjust TMPDIR if it was intended to be inside the workspace before cleaning
    }

    stages {
        stage('Clean Workspace') {
            agent any // Or a specific agent if cleanWs needs a particular environment
            steps {
                cleanWs() // Clean the workspace before using the docker agent
            }
        }

        stage('Build and Deploy') {
            agent {
                docker {
                    image 'node:20-alpine'
                    args '-u root:root'
                }
            }
            steps {
                // All subsequent steps run inside the docker container
                // Prepare Environment (moved inside docker agent)
                sh 'node --version'
                sh 'npm --version'
                sh 'df -h'
                sh 'pwd'
                sh 'ls -la .'

                // Clone Repository (moved inside docker agent)
                checkout scm

                // Clean Install & Build (moved inside docker agent)
                script {
                    sh 'rm -rf node_modules package-lock.json || true'
                    sh 'npm cache clean --force || true'
                    sh 'mkdir -p .npm-cache'
                    sh '''#!/bin/bash
                    export NPM_CONFIG_CACHE="./.npm-cache"
                    export NPM_CONFIG_LOGLEVEL="verbose"
                    echo "Installing dependencies with npm ci..."
                    npm ci || {
                        echo "npm ci failed, falling back to npm install..."
                        npm install --no-audit --prefer-offline
                    }
                    if [ ! -d "node_modules" ]; then
                        echo "Failed to install dependencies."
                        exit 1
                    fi
                    '''
                }

                // Build Vue Application (moved inside docker agent)
                 script {
                    sh '''#!/bin/bash
                    echo "Building Vue application..."
                    npm run build
                    if [ ! -d "dist" ]; then
                        echo "Build failed - no dist directory found."
                        exit 1
                    else
                        echo "Build succeeded. Contents of dist directory:"
                        ls -la dist
                    fi
                    '''
                }

                // Build Docker Image (moved inside docker agent)
                script {
                    docker.build("${DOCKER_IMAGE}:latest", '.')
                }

                // Login and Push Image (moved inside docker agent)
                script {
                    docker.withRegistry('https://registry-1.docker.io/v2/', DOCKER_CREDENTIALS) {
                          echo "🔐 Credential loaded for Docker Hub"
                          docker.image("${DOCKER_IMAGE}:latest").push()
                    }
                }

                // Deploy Container (moved inside docker agent)
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
        // Optional: Another cleanWs here if you want to be extra sure, but usually not necessary
        // always {
        //     cleanWs()
        // }
    }
}