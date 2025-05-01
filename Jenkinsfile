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
                echo "🧹 Cleaning workspace on the Jenkins agent host..."
                cleanWs()
            }
        }

        stage('Install and Build Vue App') {
            agent {
                docker {
                    image 'node:22' // Optional: use 'node:22-alpine' for lighter image
                    args '-u 111:113'
                }
            }
            steps {
                script {
                    echo "📦 Running build inside Docker container as user 111:113..."

                    // Diagnostic
                    sh 'set -x'
                    checkout scm

                    // Node + NPM Versions
                    sh 'node -v && npm -v'

                    // Install + Build
                    sh '''
                        export NPM_CONFIG_CACHE=/tmp/.npm
                        mkdir -p $NPM_CONFIG_CACHE

                        echo "📦 Installing dependencies..."
                        rm -rf node_modules package-lock.json || true
                        npm ci || npm install --no-audit --prefer-offline

                        echo "🔨 Building Vue app..."
                        npm run build

                        if [ ! -d dist ]; then
                            echo "❌ Build failed - dist directory missing."
                            exit 1
                        fi

                        echo "✅ Build successful. Contents of dist:"
                        ls -la dist

                        echo "🧹 Cleaning npm cache..."
                        rm -rf $NPM_CONFIG_CACHE
                    '''
                }
            }
        }

        stage('Build and Push Docker Image') {
            agent any
            steps {
                script {
                    echo "🐳 Building Docker image on host..."

                    docker.withRegistry('https://registry-1.docker.io/v2/', DOCKER_CREDENTIALS) {
                        def image = docker.build("${DOCKER_IMAGE}:latest", '.')
                        echo "🚀 Pushing image to Docker Hub..."
                        image.push()
                    }

                    echo "✅ Docker image build & push complete."
                }
            }
        }

        stage('Deploy Container') {
            agent any
            steps {
                script {
                    echo "📦 Deploying container..."

                    sh '''
                        echo "🧹 Pruning old images..."
                        docker image prune -f

                        echo "🛑 Stopping old container..."
                        docker stop pulsepoint-container || true

                        echo "🗑️ Removing old container..."
                        docker rm pulsepoint-container || true

                        echo "🚀 Running new container..."
                        docker run -d --name pulsepoint-container -p 80:80 ${DOCKER_IMAGE}:latest
                    '''
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
