#!/usr/bin/env groovy

pipeline {
    // All Linux agents have ruby + bundle installed through `asdf`
    agent { label 'linux-amd64-docker' }

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 15, unit: 'MINUTES')
        timestamps()
    }

    stages {
        stage('Prepare Puppet Project') {
            steps {
                // Install Dependencies once for all
                sh 'bash ./scripts/setupgems.sh'
                // For auditing purposes: if tests are failing with "module not found" or "object not found" for instance
                archiveArtifacts '.fixtures.yml'
            }
        }
        stage('Verify') {
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
