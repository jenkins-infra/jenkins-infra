forge 'http://forge.puppetlabs.com'

# Install and manage r10k
mod 'puppet-r10k', '10.3.0'
mod 'puppet-systemd', '5.0.0'

mod 'puppetlabs-stdlib', '8.6.0'

# Used for installing gems for the puppetserver, like with hiera-eyaml
mod 'puppetlabs-puppetserver_gem', '1.1.0' # Required by datadog_agent - https://forge.puppet.com/modules/datadog/datadog_agent/dependencies
mod 'puppetlabs-inifile', '1.4.3'
mod 'puppetlabs-vcsrepo', '1.1.0'
mod 'puppetlabs-ruby', '1.0.1' # Required by datadog_agent - https://forge.puppet.com/modules/datadog/datadog_agent/dependencies

# Used for setting up ntp daemons on all machines to have a correct time
mod 'puppetlabs-ntp', '7.3.0'

# https://puppet.com/docs/puppet/6/type.html#supported-type-modules-in-puppet-agent
mod 'puppetlabs-mount_core', '1.2.0'
mod 'puppetlabs-cron_core', '1.2.0'

# Module for managing sudoers across all machines
mod 'saz-sudo', '5.0.0'

# Needed for managing firewall rules
mod 'puppetlabs-firewall', '4.0.1'

# Needed for managing .yaml files from within Puppet
mod 'reidmv-yamlfile'
# Needed by `yamlfile`
mod 'adrien-filemapper'

mod 'puppetlabs-docker', '6.1.0'

# Package Managers
mod 'puppetlabs-apt', '9.0.2'
mod 'rootexpert-snap', '1.1.0'

# Apache and its dependencies
mod 'puppetlabs-apache', '9.1.2'

mod 'puppetlabs-concat', '7.3.3'

# For managing server-side ssh configuration options
mod 'saz-ssh', '5.0.0'
# Dependency
mod 'puppetlabs-sshkeys_core', '2.4.0'

mod 'puppetlabs-lvm', '1.4.0'
mod 'datadog-datadog_agent', '3.20.0'

# Used for grabbing certificates for jenkins.io
mod 'puppet-letsencrypt', '9.2.0'

# For managing dependencies
mod 'puppetlabs-augeas_core', '1.2.0'
mod 'herculesteam-augeasproviders_shellvar', '2.2.1'
mod 'herculesteam-augeasproviders_core', '2.1.2'

# Needed for the Jenkins module
mod 'puppetlabs-java', '3.3.0'
mod 'puppet-archive', '1.1.2'

# Helpful for managing ulimits for users systematically
mod 'erwbgy-limits', '0.3.1'

# For managing sysctl configuration
mod 'herculesteam-augeasproviders_sysctl', '2.2.1'

##### The following custom puppet modules must be specified with 1 attribute per line
# Example:
#  mod 'modulename'
#    :git => <git URL>,
#    :ref => <git ref>,
#####

# Dependencies for the Puppet IRC report processor, using our forked version
# which updates on any changed status
mod 'irc',
  :git => 'https://github.com/jenkins-infra/puppet-irc.git',
  :ref => '4e5e437'
# Needed for managing our accounts in hiera, this fork contains the pull
# request which adds support for multiple SSH keys:
# <https://github.com/torrancew/puppet-account/pull/18>
mod 'account',
  :git => 'https://github.com/jenkins-infra/puppet-account.git',
  :ref => '1deebe9'
mod 'jenkins_keys',
  :git => 'git@github.com:jenkins-infra/jenkins-keys.git',
  :ref => 'eeb7db7'
