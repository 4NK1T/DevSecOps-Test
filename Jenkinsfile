pipeline {
    agent any

    environment {
        DOJO_URL = 'http://localhost:8080' // DefectDojo URL
        DOJO_API_KEY = '006ec9ad0e9eaf04b21212ecb12268dd9da9c9cf' // DefectDojo API key
        DEPENDENCY_CHECK_PATH = '/opt/dependency-check/bin/dependency-check.sh' // Path to Dependency-Check CLI
    }

    stages {
        stage('Checkout Code') {
            steps {
                echo 'Checking out code from GitHub...'
                checkout scm
            }
        }

        stage('Dependency-Check (CLI)') {
            steps {
                echo 'Running Dependency-Check using CLI...'
                sh '''
                ${DEPENDENCY_CHECK_PATH} \
                    --project "DevSecOps-Test" \
                    --scan . \
                    --format JSON \
                    --out dependency-check-report.json
                '''
            }
            post {
                always {
                    archiveArtifacts artifacts: 'dependency-check-report.json', allowEmptyArchive: true
                    echo 'Dependency-Check completed. Results archived.'
                }
            }
        }

        stage('Snyk Scan (CLI)') {
    steps {
        echo 'Running Snyk scan using CLI...'
        withCredentials([string(credentialsId: 'snyk-api-key-id', variable: 'SNYK_TOKEN')]) {
            sh '''
            # Run Snyk test and allow the pipeline to continue regardless of exit code
            snyk test --json || true
            '''
        }
    }
    post {
        always {
            archiveArtifacts artifacts: 'snyk-results.json', allowEmptyArchive: true
            echo 'Snyk scan completed. Results archived.'
        }
    }

    stage('Upload Results to DefectDojo') {
            steps {
                echo 'Uploading results to DefectDojo...'
                script {
                    // Upload Dependency-Check results
                    sh '''
                    curl -X POST "${DOJO_URL}/api/v2/import-scan/" \
                         -H "Authorization: Token ${DOJO_API_KEY}" \
                         -H "Content-Type: application/json" \
                         -d @dependency-check-report.json
                    '''

                    // Upload Snyk results
                    sh '''
                    curl -X POST "${DOJO_URL}/api/v2/import-scan/" \
                         -H "Authorization: Token ${DOJO_API_KEY}" \
                         -H "Content-Type: application/json" \
                         -d @snyk-results.json
                    '''
                }
            }
        }
    }

    post {
        always {
            echo 'Pipeline execution completed.'
        }
    }
}
