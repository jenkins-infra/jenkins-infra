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
                        sh 'bundle exec parallel_rspec spec/defines'
                        junit 'tmp/rspec*.xml'
                    }
                }
                stage('vhost check') {
                    agent { label 'ruby' }
                    steps {
                        // Check that Confluence rewrite rules that contain '#' also include the 'NE' attribute
                        // to assure that the '#' in the rewrite is not escaped.
                        // This is an imperfect test that would have detected the most recent failures
                        sh 'if grep "RewriteRule.*#" dist/profile/templates/confluence/vhost.conf | grep -v NE,NC,L,QSA; then echo "Suspicious reference to ID in confluence RewriteRule URL without no expansion (NE) flag"; exit 1; fi'
                        // Check that Confluence rewrite rules don't duplicate the mistake of adding an extra
                        // '/' after the JENKINS portion of the URL.
                        sh 'if grep JENKINS// dist/profile/templates/confluence/vhost.conf; then echo "Extra / after JENKINS in Confluence URL"; exit 1; fi'
                        // Check confluence URLs from vhost.conf file
                        sh 'scripts/verify_confluence_urls.rb'
                    }
                }
                stage('acceptance tests for jenkins::master') {
                    agent { label 'docker' }
                    steps {
                        sh '''
                        # Install vagrant and bundler (to allow rubygems)
                        curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
                        sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
                        sudo apt-get update && sudo apt-get install -y vagrant bundler
                        '''

                        sh '''
                        # Bootstrap Vagrant installation
                        echo "> Installing Vagrant Plugin for serverspec"
                        ## When using the upstream version
                        # vagrant plugin install vagrant-serverspec
                        ## When using the custom versions (dueto Docker provider)
                        temp_repo="${TMPDIR:-/tmp}/vagrant-serverspec"
                        rm -rf "${temp_repo}"
                        git clone https://github.com/dduportal/vagrant-serverspec "${temp_repo}"
                        cd "${temp_repo}"
                        gem build ./vagrant-serverspec.gemspec
                        vagrant plugin install ./vagrant-serverspec-1.5.3.gem
                        cd -

                        ./vagrant-bootstrap
                        '''

                        sh '''
                        docker info
                        vagrant up --provider=docker jenkins::master
                        vagrant provision jenkins::master
                        vagrant destroy -f jenkins::master
                        '''
                    }
                    post {
                        always {
                            sh '''
                            vagrant destroy -f
                            '''
                        }
                    }
                }
            }
        }
    }
}
// vim: ft=groovy
