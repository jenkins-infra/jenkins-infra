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
    }

    stages {
        stage('Prepare Dependencies') {
            agent { label 'ruby' }
            /* These environment variables make it feasible for Git to clone properly while
            * inside the wacky confines of a Docker container
            */
            environment {
                GIT_COMMITTER_EMAIL = 'me@hatescake.com'
                GIT_COMMITTER_NAME = 'Hates'
                GIT_AUTHOR_NAME = 'Cake'
                GIT_AUTHOR_EMAIL = 'hates@cake.com'
            }

            steps {
                /* Some gems seem to want to stuff things into hidden
                * directories under $HOME, e.g.
                *   Could not initialize global default settings:
                *   Permission denied - /.puppetlabs
                */
                sh 'HOME=$PWD bundle install --without development plugins --path vendor/gems'
                sh 'HOME=$PWD bundle exec rake spec_clean spec_prep'

                /*
                 * Ignoring spec/fixtures which can include non-ASCII data that
                 * causes problems with our stash
                 */
                stash includes: '.bundle/**,vendor/**,spec/fixtures/modules/**',
                          name: 'deps',
                      excludes: 'vendor/**/spec/fixtures/**'
            }
        }

        stage('Verify') {
            failFast true
            parallel {
                stage('Syntax') {
                    agent { label 'ruby' }
                    steps {
                        unstash 'deps'
                        sh 'bundle exec rake lint'
                    }
                }
                stage('Profiles') {
                    agent { label 'ruby' }
                    steps {
                        unstash 'deps'
                        sh 'bundle exec parallel_rspec spec/classes/profile'
                    }
                }
                stage('Roles') {
                    agent { label 'ruby' }
                    steps {
                        unstash 'deps'
                        sh 'bundle exec parallel_rspec spec/classes/role'
                        sh 'bundle exec parallel_rspec spec/defines'
                    }
                }
            }
        }
    }
}
// vim: ft=groovy
