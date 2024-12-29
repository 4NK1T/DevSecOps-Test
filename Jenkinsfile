pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'php-app' // Docker image name
        DOCKER_CONTAINER = 'php-app-container' // Docker container name
        APP_PORT = '8082' // External port for the app
        SEMGREP_TOKEN = '7c820b8783e581bd98899f071aed85020cdf72dd1cced16e06c194d68a699be8'
        GRAFANA_API_TOKEN = 'glsa_IHsnKKyhuHjmiHKHsF822IjlxVvZ3Ofr_ae4155b8'
        DOJO_URL = 'http://localhost:8081'
    }

    stages {
        stage('Checkout Code') {
            steps {
                echo 'Checking out code from GitHub...'
                checkout scm
            }
        }

        stage('Static Code Analysis with Semgrep') {
            steps {
                echo 'Running Semgrep for static code analysis...'
                sh '''
                semgrep --config auto --json --output semgrep-results.json
                '''
            }
            post {
                always {
                    archiveArtifacts artifacts: 'semgrep-results.json', allowEmptyArchive: true
                    echo 'Semgrep analysis completed. Results archived.'
                }
            }
        }

        stage('Dependency Scanning with Snyk') {
            steps {
                echo 'Running Snyk to scan dependencies...'
                sh '''
                snyk auth ${SEMGREP_TOKEN}
                snyk test --json > snyk-results.json
                '''
            }
            post {
                always {
                    archiveArtifacts artifacts: 'snyk-results.json', allowEmptyArchive: true
                    echo 'Snyk dependency scan completed. Results archived.'
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                echo 'Building Docker image...'
                sh '''
                docker build -t ${DOCKER_IMAGE} .
                '''
            }
        }

        stage('Scan Docker Image with Trivy') {
            steps {
                echo 'Scanning Docker image with Trivy...'
                sh '''
                trivy image --exit-code 0 --severity HIGH ${DOCKER_IMAGE}
                trivy image --exit-code 1 --severity CRITICAL ${DOCKER_IMAGE}
                '''
            }
        }

        stage('Run Docker Container') {
            steps {
                echo 'Running Docker container...'
                sh '''
                docker stop ${DOCKER_CONTAINER} || true
                docker rm ${DOCKER_CONTAINER} || true
                docker run -d -p ${APP_PORT}:80 --name ${DOCKER_CONTAINER} ${DOCKER_IMAGE}
                '''
            }
        }

        stage('Dynamic Application Security Testing (DAST) with OWASP ZAP') {
            steps {
                echo 'Running OWASP ZAP scan on http://localhost:${APP_PORT}...'
                sh '''
                zap-cli start --start-options '-config api.disablekey=true' -d
                zap-cli quick-scan http://localhost:${APP_PORT}
                zap-cli report -o zap-report.html -f html
                zap-cli stop
                '''
            }
            post {
                always {
                    archiveArtifacts artifacts: 'zap-report.html', allowEmptyArchive: true
                    echo 'OWASP ZAP scan completed. Report archived.'
                }
            }
        }

        stage('Upload Results to DefectDojo') {
            steps {
                echo 'Uploading results to DefectDojo...'
                sh '''
                curl -X POST "${DOJO_URL}/api/v2/import-scan/" \
                     -H "Authorization: Token ${SEMGREP_TOKEN}" \
                     -H "Content-Type: application/json" \
                     -d @semgrep-results.json

                curl -X POST "${DOJO_URL}/api/v2/import-scan/" \
                     -H "Authorization: Token ${SEMGREP_TOKEN}" \
                     -H "Content-Type: application/json" \
                     -d @snyk-results.json

                curl -X POST "${DOJO_URL}/api/v2/import-scan/" \
                     -H "Authorization: Token ${SEMGREP_TOKEN}" \
                     -H "Content-Type: application/json" \
                     -d @zap-report.html
                '''
            }
        }

        stage('Monitoring and Reporting with Grafana') {
            steps {
                echo 'Sending metrics to Grafana...'
                sh '''
                curl -X POST http://localhost:3000/api/annotations \
                     -H "Authorization: Bearer ${GRAFANA_API_TOKEN}" \
                     -H "Content-Type: application/json" \
                     -d '{"text":"Security Scan Completed","tags":["jenkins","security"],"time":$(date +%s000)}'
                '''
            }
        }
    }

    post {
        always {
            echo 'Pipeline completed. Cleaning up resources...'
            sh '''
            docker stop ${DOCKER_CONTAINER} || true
            docker rm ${DOCKER_CONTAINER} || true
            '''
        }
    }
}
