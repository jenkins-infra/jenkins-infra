#!/usr/bin/env groovy

/*
 * This script is meant to be executed by a Jenkins controller.
 *
 * This script sets up some bare configuration for the Git plugin to properly
 * execute some git commands.
 */
import jenkins.model.Jenkins
import org.jenkinsci.plugins.gitclient.*
import hudson.plugins.git.*

def gitConfig = Jenkins.instance.getDescriptor('hudson.plugins.git.GitSCM')

gitConfig.globalConfigName = 'oscar'
gitConfig.globalConfigEmail = 'oscar@example.com'
gitConfig.save()


/* Ensure that we have the Git tool default set to JGit. This was originally
 * done manually, but this script will enforce the setting moving forward
 */
def tools = Jenkins.instance.getDescriptor('hudson.plugins.git.GitTool')

GitTool[] gitTools = new GitTool[1]
gitTools[0] = new JGitTool()

tools.installations = gitTools
tools.save()
