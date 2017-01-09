#!/usr/bin/env groovy

# This script is meant to be executed by a Jenkins master.
#
# This script sets up some bare configuration for the Git plugin to properly
# execute some git commands.

def gitConfig = Jenkins.instance.getDescriptor('hudson.plugins.git.GitSCM')

gitConfig.globalConfigName = 'oscar'
gitConfig.globalConfigEmail = 'oscar@example.com'
gitConfig.save()
