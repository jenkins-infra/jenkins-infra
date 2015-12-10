/*
 * This is a multibranch workflow file for defining how this project should be
 * built, tested and deployed
 */

def nodeLabel = 'docker'

node(nodeLabel) {
    stage 'Clean workspace'
    /* Running on a fresh Docker instance makes this redundant, but just in
     * case the host isn't configured to give us a new Docker image for every
     * build, make sure we clean things before we do anything
     */
    deleteDir()


    stage 'Checkout source'
    /*
     * Represents the SCM configuration in a "Workflow from SCM" project build. Use checkout
     * scm to check out sources matching Jenkinsfile with the SCM details from
     * the build that is executing this Jenkinsfile.
     *
     * when not in multibranch: https://issues.jenkins-ci.org/browse/JENKINS-31386
     */
    checkout scm


    stage 'Prepare Ruby'
    /* if we can't install everything we need for Ruby in less than 15 minutes
     * we might as well just give up
     */
    timeout(15) {
        // let's assume bundler exists on the system
        //sh 'gem install bundler --no-ri --no-rdoc --verbose'
        sh 'mkdir -p vendor/gems'
        /*
         * For this to succeed we basically need:
         *  ruby
         *  git
         *  build-essential
         *  zlibc
         */
        sh 'bundle install --without development --path=vendor/gems'
    }
    /* stashing our install gems directory so we can re-use it for
     * parallelization of tasks later
     */
    stash includes: 'vendor/**', name: 'gems'

    /* Since we have multiple discrete tasks that can be executed in parallel
     * to qualify the "current build" of jenkins-infra, we can use the
     * `parallel` workflow step and span out to multiple build nodes
     * independently
     */
    parallel(
        linting: {
            node(nodeLabel) {
                sh 'ls ; pwd'
                // this seems to cause https://issues.jenkins-ci.org/browse/JENKINS-23271
                //unstash 'gems'
                //sh 'ls ; pwd'
            }
        },
        rspec: {
            node(nodeLabel) {
                sh 'ls ; pwd'
                //unstash 'gems'
                //sh 'ls ; pwd'
            }
        },
        failFast: true)
}

// vim: ft=groovy
