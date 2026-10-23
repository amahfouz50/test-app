pipeline {
    agent any

    options {
        timeout(time: 15, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timestamps()
    }

    environment {
        APP_NAME        = 'test-app'
        IMAGE_NAME      = 'test-app:latest'
        CONTAINER       = 'shms-test-app'
        GIT_REPO_URL    = 'https://github.com/amahfouz50/test-app.git'
        BRANCH_NAME     = 'develop'
        NOTIFICATION_TO = 'ahmedmahfouz13@gmail.com, ahmedmahfouz1993@gmail.com'
    }

    stages {
        stage('Checkout develop Branch') {
            steps {
                echo "📥 Checking out branch ${env.BRANCH_NAME} from ${env.GIT_REPO_URL}..."
                git branch: env.BRANCH_NAME,
                    url: env.GIT_REPO_URL
            }
        }

        stage('Clean & Test (Maven)') {
            steps {
                echo "🔨 Cleaning and running unit tests with Maven..."
                sh 'mvn clean test -B --no-transfer-progress'
            }
        }

        stage('Remove Old Image & Container') {
            steps {
                echo "🧹 Stopping running container and removing old image..."
                sh '''
                    # Force stop and remove container by name if running (handles any previous project names)
                    docker rm -f ${CONTAINER} || true
                    
                    # Stop and remove compose project resources
                    docker compose -p ${APP_NAME} down --remove-orphans || true
                    
                    # Remove old image if exists
                    if docker image inspect ${IMAGE_NAME} > /dev/null 2>&1; then
                        echo "Removing old image: ${IMAGE_NAME}"
                        docker rmi -f ${IMAGE_NAME} || true
                    else
                        echo "No existing image ${IMAGE_NAME} found."
                    fi
                '''
            }
        }

        stage('Build New Docker Image') {
            steps {
                echo "🐳 Building new Docker image with docker compose..."
                sh 'docker compose -p ${APP_NAME} build --no-cache'
            }
        }

        stage('Run Docker Compose') {
            steps {
                echo "🚀 Starting container with docker compose up -d..."
                sh 'docker compose -p ${APP_NAME} up -d'
            }
        }

        stage('Health Check') {
            steps {
                echo "🩺 Verifying application health check on port 7012..."
                sh '''
                    echo "Waiting for Spring Boot to start up..."
                    sleep 15

                    for i in $(seq 1 15); do
                        HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://host.docker.internal:7012/actuator/health || true)
                        if [ "$HTTP_CODE" = "200" ]; then
                            echo "✅ Application is HEALTHY (HTTP 200) on host.docker.internal:7012!"
                            echo "Response from /api/test:"
                            curl -s http://host.docker.internal:7012/api/test
                            echo ""
                            exit 0
                        fi
                        echo "Healthcheck attempt $i/15 returned HTTP $HTTP_CODE, waiting 5s..."
                        sleep 5
                    done
                    echo "❌ Healthcheck failed!"
                    docker compose -p ${APP_NAME} logs --tail=50
                    exit 1
                '''
            }
        }
    }

    post {
        success {
            echo "🎉 Pipeline finished successfully! ${APP_NAME} is deployed and healthy on http://localhost:7012"
            script {
                try {
                    emailext (
                        to: env.NOTIFICATION_TO,
                        subject: "✅ SUCCESS: Pipeline [${env.JOB_NAME}] - Build #${env.BUILD_NUMBER}",
                        mimeType: 'text/html',
                        body: """
                            <div style="font-family: Arial, sans-serif; padding: 20px; border: 1px solid #4CAF50; border-radius: 8px;">
                                <h2 style="color: #4CAF50;">✅ Pipeline Build Succeeded!</h2>
                                <p><b>Project:</b> ${env.JOB_NAME}</p>
                                <p><b>Build Number:</b> #${env.BUILD_NUMBER}</p>
                                <p><b>Branch:</b> ${env.BRANCH_NAME}</p>
                                <p><b>Status:</b> SUCCESS</p>
                                <hr style="border: 0; border-top: 1px solid #eee; margin: 15px 0;">
                                <p><b>App URL:</b> <a href="http://localhost:7012">http://localhost:7012</a></p>
                                <p><b>Health Check:</b> <a href="http://localhost:7012/actuator/health">http://localhost:7012/actuator/health</a></p>
                                <p><b>Build Details:</b> <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></p>
                            </div>
                        """
                    )
                } catch (Exception e) {
                    echo "⚠️ Email notification failed (verify SMTP configuration in Jenkins): ${e.message}"
                }
            }
        }
        failure {
            echo "❌ Pipeline failed! Inspecting container logs..."
            sh 'docker compose -p ${APP_NAME} logs --tail=50 || true'
            script {
                try {
                    emailext (
                        to: env.NOTIFICATION_TO,
                        subject: "❌ FAILURE: Pipeline [${env.JOB_NAME}] - Build #${env.BUILD_NUMBER}",
                        mimeType: 'text/html',
                        body: """
                            <div style="font-family: Arial, sans-serif; padding: 20px; border: 1px solid #F44336; border-radius: 8px;">
                                <h2 style="color: #F44336;">❌ Pipeline Build Failed!</h2>
                                <p><b>Project:</b> ${env.JOB_NAME}</p>
                                <p><b>Build Number:</b> #${env.BUILD_NUMBER}</p>
                                <p><b>Branch:</b> ${env.BRANCH_NAME}</p>
                                <p><b>Status:</b> FAILED</p>
                                <hr style="border: 0; border-top: 1px solid #eee; margin: 15px 0;">
                                <p><b>Build Details:</b> <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></p>
                                <p><b>Console Output:</b> <a href="${env.BUILD_URL}console">${env.BUILD_URL}console</a></p>
                            </div>
                        """
                    )
                } catch (Exception e) {
                    echo "⚠️ Email notification failed (verify SMTP configuration in Jenkins): ${e.message}"
                }
            }
        }
    }
}
