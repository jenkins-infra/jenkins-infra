#!/usr/bin/env groovy

pipeline {
    agent none

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 1, unit: 'HOURS')
        timestamps()
    }

    stages {
        stage('Verify DNS') {
            agent { label 'alpine' }

            steps {
                sh 'apk add -U bind'
                sh '/usr/sbin/named-checkzone jenkins.io dist/profile/files/bind/jenkins.io.zone'
                sh '/usr/sbin/named-checkzone jenkins-ci.org dist/profile/files/bind/jenkins-ci.org.zone'
            }
        }

        stage('Verify Puppet') {
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
                sh 'HOME=$PWD bundle exec rake resolve'
                sh 'bundle exec rake lint'
                sh 'bundle exec parallel_rspec spec/classes'
                sh 'bundle exec parallel_rspec spec/defines'
            }
        }
    }
}
// vim: ft=groovy
