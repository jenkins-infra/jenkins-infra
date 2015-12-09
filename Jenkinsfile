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
        sh 'gem install bundler -N --verbose'
        sh 'mkdir -p vendor/gems'
        sh 'bundle install --verbose --without development --path=vendor/gems'
    }
    /* stashing our install gems directory so we can re-use it for
     * parallelization of tasks later
     */
    stash includes: 'vendor/gems', name: 'gems'


    /* Executing some sub-workflows in parallel */
    parallel(
        linting: {
            node(nodeLabel) {
                unstash 'gems'
                sh 'ls'
            }
        },
        rspec: {
            node(nodeLabel) {
                unstash 'gems'
                sh 'ls'

            }
        },
        failFast: true)
}


// vim: ft=groovy
