forge 'http://forge.puppetlabs.com'

# Install and manage r10k
mod 'puppet-r10k', '6.8.0'

# Deps for zack/r10k
mod 'puppetlabs-stdlib', '5.2.0'

mod 'puppetlabs-ruby', '1.0.1'
mod 'puppetlabs-gcc', '0.3.0'
# Used for installing gems for the puppetserver, like with hiera-eyaml
mod 'puppetlabs-puppetserver_gem', '1.1.0'
mod 'puppetlabs-inifile', '1.4.3'
mod 'puppetlabs-vcsrepo', '1.1.0'

# Used for setting up ntp daemons on all machines to have a correct time
mod 'puppetlabs-ntp', '7.3.0'

# https://puppet.com/docs/puppet/6/type.html#supported-type-modules-in-puppet-agent
mod 'puppetlabs-mount_core', '1.1.0'
mod 'puppetlabs-cron_core', '1.1.0'

# Module for managing sudoers across all machines
mod 'saz-sudo', '5.0.0'

# Needed for managing firewall rules
mod 'puppetlabs-firewall', '3.0.1'

# Needed for managing .yaml files from within Puppet
mod 'reidmv-yamlfile'
# Needed by `yamlfile`
mod 'adrien-filemapper'

mod 'puppetlabs-docker', '4.4.0'

# Deps for docker
mod 'puppetlabs-apt', '8.5.0'

# Apache and its dependencies
mod 'puppetlabs-apache', '8.1.0'

mod 'puppetlabs-concat', '5.2.0'

# For managing server-side ssh configuration options
mod 'saz-ssh', '5.0.0'
# Dependency
mod 'puppetlabs-sshkeys_core', '1.0.2'

mod 'puppetlabs-lvm', '1.4.0'
mod 'datadog-datadog_agent', '3.17.0'

# Used for grabbing certificates for jenkins.io
mod 'puppet-letsencrypt', '6.0.0'

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
# Used internally to gzip compress rotated logs
mod 'apachelogcompressor',
  :git => 'https://github.com/jenkins-infra/puppet-apachelogcompressor.git',
  :ref => '0113d7b'
