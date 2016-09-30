#!/usr/bin/env groovy

def nodeLabel = 'docker'
def dockerImage = 'rtyler/jenkins-infra-builder'

/* Only keep the 10 most recent builds. */
properties([[$class: 'BuildDiscarderProperty',
                strategy: [$class: 'LogRotator', numToKeepStr: '10']]])

parallel(lint: {
            node(nodeLabel) {
                runInside(dockerImage) {
                    sh 'mkdir -p vendor/gems && bundle install --without development plugins --path=vendor/gems'
                    sh 'bundle exec rake lint'
                }
            }
        },
        verifyZoneFiles: {
            node(nodeLabel) {
                validateZoneFor('jenkins-ci.org', dockerImage)
                validateZoneFor('jenkins.io', dockerImage)
            }
        },
        rspec: {
            node(nodeLabel) {
                runInside(dockerImage) {
                    sh 'mkdir -p vendor/gems && bundle install --without development plugins --path=vendor/gems'
                    /* Some gems seem to want to stuff things into hidden
                     * directories under $HOME, e.g.
                     *   Could not initialize global default settings:
                     *   Permission denied - /.puppetlabs
                     */
                    sh 'HOME=$PWD bundle exec rake spec'
                }
            }
        },
    )

def validateZoneFor(dnsZone, dockerImage) {
    runInside(dockerImage) {
        sh "/usr/sbin/named-checkzone ${dnsZone} dist/profile/files/bind/${dnsZone}.zone"
    }
}

def runInside(String dockerImage, Closure c) {
    /* These environment variables make it feasible for Git to clone properly while
    * inside the wacky confines of a Docker container
    */
    List gitEnv = [
                    'GIT_COMMITTER_EMAIL=me@hatescake.com',
                    'GIT_COMMITTER_NAME=Hates',
                    'GIT_AUTHOR_NAME=Cake',
                    'GIT_AUTHOR_EMAIL=hates@cake.com',
    ]

    /* clean out our workspace before we do anything */
    deleteDir()

    /* This requires the Timestamper plugin to be installed on the Jenkins */
    timestamps {
        docker.image(dockerImage).inside {
            checkout scm
            withEnv(gitEnv) {
                c.call()
            }
        }
    }
}

// vim: ft=groovy
