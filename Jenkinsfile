pipeline {
    agent {
        docker {
            image 'node:22'           // Official Node LTS image
            args  '-u root:root'      // run as root so cleanWs can delete all files
        }
    }

    environment {
        DOCKER_IMAGE       = "ishhod08/pulsepoint"
        DOCKER_CREDENTIALS = "docker-hub-credentials"
    }

    stages {
        stage('Clean Workspace') {
            steps {
                cleanWs()
            }
        }

        stage('Clone Repository') {
            steps {
                checkout scm           // uses the Jenkinsfile’s repo/branch
            }
        }

        stage('Clean Install & Build') {
            steps {
                script {
                    sh 'rm -rf node_modules package-lock.json'
                    sh 'rm -rf node_modules/execa node_modules/.execa-*'
                    sh 'npm cache clean --force'
                    sh 'mkdir -p .npm-cache'
                    sh 'chown -R root:root .'

                    sh '''#!/bin/bash
                    for i in {1..3}; do
                      echo "Attempt $i: Installing dependencies"
                      npm install --legacy-peer-deps --cache .npm-cache --loglevel=verbose && break
                      echo "npm install failed. Retrying in 5s..."
                      sleep 5
                    done
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
