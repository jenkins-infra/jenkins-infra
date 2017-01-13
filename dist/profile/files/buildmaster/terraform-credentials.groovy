#!/usr/bin/env groovy

/* This file sets up the necessary some additional credentials for Terraforming
 * infrastructure
 */

import jenkins.model.*
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.domains.*
import org.jenkinsci.plugins.plaincredentials.impl.*
import hudson.util.Secret


def scope = CredentialsScope.GLOBAL
List credentials = []


credentials.add(new StringCredentialsImpl(scope,
                                        'azure-terraform-k8s-ssh-key',
                                        'Azure Kubernetes Public SSH Key',
                                        Secret.fromString((new File(Jenkins.instance.rootDir, '.ssh/azure_k8s.pub')).text)))


credentials.each { c ->
    SystemCredentialsProvider.instance.store.addCredentials(Domain.global(), c)
}
