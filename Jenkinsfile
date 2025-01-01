pipeline {
    agent any

    environment {
        DOJO_URL = 'http://localhost:8080' // DefectDojo URL
        DOJO_API_KEY = '006ec9ad0e9eaf04b21212ecb12268dd9da9c9cf' // DefectDojo API key
    }

    stages {
        stage('Checkout Code') {
            steps {
                echo 'Checking out code from GitHub...'
                checkout scm
            }
        }

        stage('Dependency-Check (Jenkins Plugin)') {
            steps {
                echo 'Running Dependency-Check using Jenkins plugin...'
                dependencyCheck additionalArguments: '--format JSON', odcInstallation: 'Default'
            }
            post {
                always {
                    archiveArtifacts artifacts: '**/dependency-check-report.json', allowEmptyArchive: true
                    echo 'Dependency-Check completed. Results archived.'
                }
            }
        }

        stage('Snyk Scan (CLI)') {
            steps {
                echo 'Running Snyk scan using CLI...'
                sh '''
                # Authenticate Snyk (if not already authenticated globally)
                snyk auth || true

                # Run Snyk test and generate JSON output
                snyk test --json > snyk-results.json
                '''
            }
            post {
                always {
                    archiveArtifacts artifacts: 'snyk-results.json', allowEmptyArchive: true
                    echo 'Snyk scan completed. Results archived.'
                }
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
