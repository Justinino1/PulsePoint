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
            agent {
                docker {
                    image 'node:20-alpine'
                    // Specify the user and group ID of the Jenkins user on the host
                    // Replace YOUR_JENKINS_USER_UID and YOUR_JENKINS_USER_GID
                    // Based on your logs, this is likely '111:113'
                    args '111:113'

                    // Commented out the optional NPM cache mount for now
                    // args '-v $HOME/.npm:/root/.npm'
                }
            }
            steps {
                script {
                    echo "Running steps inside the Docker container as host Jenkins user..."

                    // Keep or remove the debugging steps as needed now that we understand the cause
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

                    // ... rest of your stages (node --version, npm --version, checkout, etc.) ...
                }
            }
        }

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