pipeline {
    agent any

    options {
        timeout(time: 15, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timestamps()
    }

    environment {
        APP_NAME     = 'test-app'
        IMAGE_NAME   = 'test-app:latest'
        CONTAINER    = 'shms-test-app'
        GIT_REPO_URL = 'https://github.com/amahfouz50/test-app.git'
        BRANCH_NAME  = 'develop'
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
                    sleep 10
                    TARGET_HOST="host.docker.internal"
                    
                    # Check if host.docker.internal or localhost is reachable
                    if ! curl -s -o /dev/null http://${TARGET_HOST}:7012/actuator/health; then
                        TARGET_HOST="localhost"
                    fi

                    for i in $(seq 1 12); do
                        HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://${TARGET_HOST}:7012/actuator/health || true)
                        if [ "$HTTP_CODE" = "200" ]; then
                            echo "✅ Application is HEALTHY (HTTP 200) on ${TARGET_HOST}:7012!"
                            echo "Response from /api/test:"
                            curl -s http://${TARGET_HOST}:7012/api/test
                            echo ""
                            exit 0
                        fi
                        echo "Healthcheck attempt $i/12 returned HTTP $HTTP_CODE, waiting 5s..."
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
        }
        failure {
            echo "❌ Pipeline failed! Inspecting container logs..."
            sh 'docker compose -p ${APP_NAME} logs --tail=50 || true'
        }
    }
}
