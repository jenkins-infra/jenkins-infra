#!/usr/bin/env groovy
/*
 * Restrict the JNLP protocols to only those which should be enabled (modern
 * and secure ones)
 */

import jenkins.model.*
import org.kohsuke.stapler.StaplerProxy
import jenkins.security.s2m.AdminWhitelistRule

/* Restrict agent protocols to only modern and secure ones */
Jenkins.instance.agentProtocols = ['JNLP4-connect', 'Ping']
Jenkins.instance.save()

/* INFRA-659: enforce  Agent -> Master Access control */
Jenkins.instance.getExtensionList(StaplerProxy).get(AdminWhitelistRule).masterKillSwitch = false
