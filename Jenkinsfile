#!groovy

def nodeLabel = 'docker'
def dockerImage = 'rtyler/jenkins-infra-builder'


stage 'Lint'
node(nodeLabel) {
    docker.image(dockerImage).inside {
        checkout scm
        sh 'mkdir -p vendor/gems && bundle install --without development plugins --path=vendor/gems'
        sh 'bundle exec rake lint'
    }
}

stage 'Verify zonefiles'
node(nodeLabel) {
    validateZoneFor('jenkins-ci.org', dockerImage)
    validateZoneFor('jenkins.io', dockerImage)
}

stage 'Run rspec-puppet'
node(nodeLabel) {
    docker.image(dockerImage).inside {
        checkout scm
        sh 'mkdir -p vendor/gems && bundle install --without development plugins --path=vendor/gems'
        sh 'bundle exec rake spec'
    }
}

def validateZoneFor(dnsZone, dockerImage) {
    docker.image(dockerImage).inside {
        checkout scm
        sh "/usr/sbin/named-checkzone ${dnsZone} dist/profile/files/bind/${dnsZone}.zone"
    }
}

// vim: ft=groovy
