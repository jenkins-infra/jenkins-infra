#!/usr/bin/env groovy
import jenkins.model.*
import org.kohsuke.stapler.StaplerProxy
import jenkins.security.s2m.AdminWhitelistRule

/* INFRA-659: enforce  Agent -> Master Access control */
// TODO Remove once we're on 2.326+
Jenkins.instance.getExtensionList(StaplerProxy).get(AdminWhitelistRule).masterKillSwitch = false
