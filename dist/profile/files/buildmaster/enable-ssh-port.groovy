#!/usr/bin/env groovy

import jenkins.model.Jenkins

/*
 * This script is meant to be executed by a Jenkins master.
 *
 * This script sets the SSH server port in Jenkins to 22222 so it is predictable
 * for local CLI-over-SSH access
 */

def sshConfig = Jenkins.instance.getDescriptor('org.jenkinsci.main.modules.sshd.SSHD')

sshConfig.port = 22222
sshConfig.save()
