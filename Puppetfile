forge "http://forge.puppetlabs.com"

# Install and manage r10k
mod "puppet/r10k", '6.8.0'

# Deps for zack/r10k
mod "puppetlabs/stdlib", '5.2.0'

mod 'puppetlabs/ruby', '1.0.1'
mod "puppetlabs/gcc", '0.3.0'
# Used for installing gems for the puppetserver, like with hiera-eyaml
mod "puppetlabs/puppetserver_gem", '1.1.0'
mod "puppetlabs/inifile", '1.4.3'
mod "puppetlabs/vcsrepo", '1.1.0'
#mod "gentoo/portage", '2.2.0-rc1'

# Used for setting up ntp daemons on all machines to have a correct time
mod "puppetlabs/ntp", '7.3.0'

# Module for managing sudoers across all machines
mod 'saz/sudo', '5.0.0'

# Needed for managing firewall rules
mod 'puppetlabs/firewall', '1.14.0'

# Needed for managing .yaml files from within Puppet
mod 'reidmv/yamlfile'
# Needed by `yamlfile`
mod 'adrien/filemapper'

mod 'puppetlabs-docker', '4.0.1'

# Deps for docker
mod 'puppetlabs/apt', '7.4.2'
mod 'stahnma/epel', '1.2.2'

# Dependencies for the Puppet IRC report processor, using our forked version
# which updates on any changed status
mod 'irc', :git => 'git://github.com/jenkins-infra/puppet-irc.git',
           :ref => '4e5e437'

# Needed for managing our accounts in hiera, this fork contains the pull
# request which adds support for multiple SSH keys:
# <https://github.com/torrancew/puppet-account/pull/18>
mod 'account', :git => 'git://github.com/jenkins-infra/puppet-account.git',
               :ref => '1deebe9'

mod 'jenkins_keys',
  :git => 'git@github.com:jenkins-infra/jenkins-keys.git',
  :ref => 'eeb7db7'

# Apache and its dependencies
mod "puppetlabs/apache", '3.5.0'
# Used internally to gzip compress rotated logs
mod 'apachelogcompressor',
        :git => 'git://github.com/jenkins-infra/puppet-apachelogcompressor.git',
        :ref => '0113d7b'

mod "puppetlabs/concat", '5.2.0'


mod 'rtyler/groovy', '1.0.3'
# Dependency of `groovy
mod 'nanliu/staging', '0.4.0'


# For managing server-side ssh configuration options
mod 'saz/ssh', '5.0.0'
# Dependency
mod 'puppetlabs-sshkeys_core', '1.0.2'

mod 'puppetlabs/lvm', '0.3.2'
mod 'datadog/datadog_agent', '3.8.0'

# Used for grabbing certificates for jenkins.io
mod 'puppet-letsencrypt', '5.0.0'

# For managing ldap, and dependencies
mod 'camptocamp/openldap', '1.14.0'
mod 'herculesteam/augeasproviders_shellvar', '2.2.1'
mod 'herculesteam/augeasproviders_core', '2.1.2'

# Needed for the Jenkins module
mod 'puppetlabs/java', '3.3.0'
mod 'puppet/archive', '1.1.2'

# Helpful for managing ulimits for users systematically
mod 'erwbgy/limits', '0.3.1'

# Needed for managing pgsql behind Mirrorbrain
mod 'puppetlabs/postgresql', '5.12.1'

# For managing sysctl configuration
mod 'herculesteam-augeasproviders_sysctl', '2.2.1'
