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
                echo "Cleaning the workspace"
                cleanWs() // Clean the workspace before starting
            }
        }

        stage('Clone Repository') {
            steps {
                echo "Cloning the code"
                // Uses the Jenkinsfile’s repo/branch configured in job settings
                checkout scm
            }
        }

        // Removed the 'Cleanup TMP' stage (as previously discussed)

        // REMOVED: The 'Clean Install & Build' stage is removed entirely
        // because you are assuming node_modules is already present after cloning.

        stage('Build Docker Image') {
            steps {
                script {
                    echo "Building the Docker image"
                    // Build the Docker image from the Dockerfile in the workspace root.
                    // This step will now rely on node_modules being present from the clone.
                    docker.build("${DOCKER_IMAGE}:latest", '.')
                }
            }
        }

        stage('Login to Docker Hub') {
            steps {
                script {
                    echo "Logging in to Docker Hub"
                    // Authenticate with Docker Hub using defined credentials
                    docker.withRegistry('https://registry-1.docker.docker.io/v2/', DOCKER_CREDENTIALS) {
                         echo "🔐 Credential loaded for Docker Hub"
                    }
                }
            }
        }

        stage('Push Image to Docker Hub') {
            steps {
                script {
                     echo "Pushing image to Docker Hub"
                    // Authenticate within the push context and push the image
                    docker.withRegistry('https://index.docker.io/v1/', DOCKER_CREDENTIALS) {
                       docker.image("${DOCKER_IMAGE}:latest").push()
                    }
                }
            }
        }

        stage('Deploy Container') {
            steps {
                script {
                    echo "Deploying the container"
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
            echo "Cleaning workspace after build"
            cleanWs()
        }
        success {
            echo '✅ Pipeline Succeeded!'
        }
        success {
            echo '✅ Deployment Successful!' // Duplicate, keep one or refine
        }
        failure {
            echo '❌ Pipeline Failed.'
        }
        // Add other post conditions if needed (e.g., aborted)
    }
}