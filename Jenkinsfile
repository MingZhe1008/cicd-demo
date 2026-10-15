pipeline {
    agent { label 'linux-k3s' }
    options {
        skipDefaultCheckout(true)
        disableConcurrentBuilds()
        timestamps()
        timeout(time: 15, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '20'))
    }
    triggers { pollSCM('H/2 * * * *') }
    stages {
        stage('Checkout') { steps { checkout scm } }
        stage('Build and deploy') {
            steps {
                sh '''#!/usr/bin/env bash
set -euo pipefail
TAG="build-${BUILD_NUMBER}-$(git rev-parse --short=12 HEAD)"
bash scripts/deploy.sh "$TAG"
'''
            }
        }
    }
}
