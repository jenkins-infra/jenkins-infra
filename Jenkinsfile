#!/usr/bin/env groovy

pipeline {
    agent none

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 30, unit: 'MINUTES')
        timestamps()
    }

    environment {
        LANG = 'en_US.UTF-8'
        LC_CTYPE = 'en_US.UTF-8'
        /* These environment variables make it feasible for Git to clone properly while
         * inside the wacky confines of a Docker container
         */
        GIT_COMMITTER_EMAIL = 'git@example.com'
        GIT_COMMITTER_NAME = 'Git'
        GIT_AUTHOR_NAME = 'Git'
        GIT_AUTHOR_EMAIL = 'git@example.com'
    }

    stages {
        stage('Verify') {
            failFast true
            parallel {
                stage('Syntax') {
                    agent { label 'ruby' }
                    steps {
                        sh 'HOME=$PWD bundle install --without development plugins --path vendor/gems'
                        sh 'HOME=$PWD bundle exec rake spec_clean spec_prep'
                        sh 'bundle exec rake lint'
                    }
                }
                stage('Profiles') {
                    agent { label 'ruby' }
                    steps {
                        sh 'HOME=$PWD bundle install --without development plugins --path vendor/gems'
                        sh 'HOME=$PWD bundle exec rake spec_clean spec_prep'
                        sh 'bundle exec parallel_rspec spec/classes/profile'
                        junit 'tmp/rspec*.xml'
                    }
                }
                stage('Roles') {
                    agent { label 'ruby' }
                    steps {
                        sh 'HOME=$PWD bundle install --without development plugins --path vendor/gems'
                        sh 'HOME=$PWD bundle exec rake spec_clean spec_prep'
                        sh 'bundle exec parallel_rspec spec/classes/role'
                        junit 'tmp/rspec*.xml'
                    }
                }
            }
        }
    }
}
// vim: ft=groovy
