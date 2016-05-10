#!groovy

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
                    sh 'bundle exec rake spec'
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
    /* This requires the Timestamper plugin to be installed on the Jenkins */
    wrap([$class: 'TimestamperBuildWrapper']) {
        docker.image(dockerImage).inside {
            checkout scm
            c.call()
        }
    }
}

// vim: ft=groovy
