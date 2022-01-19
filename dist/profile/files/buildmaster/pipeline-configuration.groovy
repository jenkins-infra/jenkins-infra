#!/usr/bin/env groovy

/* Configure the right defaults for our Jenkins instances and their Pipeline
 * configurations
 */

import jenkins.model.*
import jenkins.plugins.git.GitSCMSource
import org.jenkinsci.plugins.workflow.cps.CpsFlowDefinition
import org.jenkinsci.plugins.workflow.libs.*
import org.jenkinsci.plugins.pipeline.modeldefinition.config.GlobalConfig


/* Add our global library properly */
GitSCMSource source= new GitSCMSource('pipeline-library',
                        'https://github.com/jenkins-infra/pipeline-library.git',
                        null, null, null, false)

LibraryConfiguration lib = new LibraryConfiguration('pipeline-library',
                                            new SCMSourceRetriever(source))

lib.implicit = true
lib.defaultVersion = 'master'
lib.includeInChangesets = false
lib.cachingConfiguration = new LibraryCachingConfiguration(180, null)

GlobalLibraries.get().libraries = [lib]


/* Set the default Docker label for Declarative Pipeline to .. wait for it ..
 * docker
 */
GlobalConfig c = GlobalConfiguration.all().find { it instanceof GlobalConfig }
c?.dockerLabel = 'docker'
