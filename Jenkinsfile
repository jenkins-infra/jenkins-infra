#!/usr/bin/env groovy

pipeline {
    // All Linux agents have ruby + bundle installed through `asdf`
    agent { label 'linux-amd64-docker' }

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 15, unit: 'MINUTES')
        timestamps()
    }

    environment {
        // To allow using ASDF shims
        PATH = "${env.PATH}:/home/jenkins/.asdf/shims:/home/jenkins/.asdf/bin"
    }

    stages {
        stage('Prepare Puppet Project') {
            steps {
                // Install `yq` until https://github.com/jenkins-infra/packer-images/pull/277 is merged and available
                sh '''
                if ! command -v yq >/dev/null 2>&1
                then
                    asdf plugin-add yq https://github.com/sudermanjr/asdf-yq.git || true
                    asdf install yq 4.25.3
                    asdf global yq 4.25.3
                fi
                '''

                // Install Dependencies once for all
                sh 'bash ./scripts/setupgems.sh'
                // For auditing purposes: if tests are failing with "module not found" or "object not found" for instance
                archiveArtifacts '.fixtures.yml'
            }
        }
        stage('Verify') {
            failFast true
            parallel {
                stage('Syntax') {
                    steps {
                        sh 'bundle exec rake lint'
                    }
                }
                stage('Profiles') {
                    steps {
                        sh 'bundle exec parallel_rspec spec/classes/profile'
                    }
                }
                stage('Roles') {
                    steps {
                        sh 'bundle exec parallel_rspec spec/classes/role'
                    }
                }
            }
        }
    }
}
