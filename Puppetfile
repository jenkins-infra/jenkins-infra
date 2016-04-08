forge "http://forge.puppetlabs.com"

# Install and manage r10k
mod "zack/r10k", '3.1.1'

# Deps for zack/r10k
# We are tracking stdlib from git because the puppet module tool
# is getting in the way when we want to upgrade newer than the
# supported module version
mod "stdlib",
        :git => 'git@github.com:puppetlabs/puppetlabs-stdlib.git',
        :ref => '4.9.0'

mod 'puppetlabs/ruby', '0.4.0'
mod "puppetlabs/gcc", '0.3.0'
# Used for installing gems for the puppetserver, like with hiera-eyaml
mod "puppetlabs/puppetserver_gem", '0.2.0'
mod "puppetlabs/inifile", '1.4.3'
mod "puppetlabs/vcsrepo", '1.1.0'
mod "puppetlabs/git", '0.4.0'
mod "gentoo/portage", '2.2.0-rc1'

# Used for setting up ntp daemons on all machines to have a correct time
mod "puppetlabs/ntp", '4.1.2'

# Module for managing sudoers across all machines
mod 'saz/sudo', '3.0.6'

# Needed for managing firewall rules
mod 'puppetlabs/firewall', '1.1.3'

# Needed for managing .yaml files from within Puppet
mod 'reidmv/yamlfile'
# Needed by `yamlfile`
mod 'adrien/filemapper'

mod 'docker', :git => 'git://github.com/jenkins-infra/garethr-docker.git',
              :ref => '951781fbeb06fa8142e851c5746c35b302a6f427'

# Deps for docker
mod 'puppetlabs/apt', '1.6.0'
mod 'stahnma/epel', '1.2.2'

# Dependencies for the Puppet IRC report processor, using our forked version
# which updates on any changed status
mod 'irc', :git => 'git://github.com/jenkins-infra/puppet-irc.git',
           :ref => 'b837df8'

# Needed for managing our accounts in hiera, this fork contains the pull
# request which adds support for multiple SSH keys:
# <https://github.com/torrancew/puppet-account/pull/18>
mod 'account', :git => 'git://github.com/jenkins-infra/puppet-account.git',
               :ref => 'a24cc4c'

mod 'jenkins_keys',
  :git => 'git@github.com:jenkins-infra/jenkins-keys.git',
  :ref => 'eeb7db7'

# Apache and its dependencies
mod "puppetlabs/apache", '1.8.1'
# Used internally to gzip compress rotated logs
mod 'apachelogcompressor',
        :git => 'git://github.com/jenkins-infra/puppet-apachelogcompressor.git',
        :ref => '0113d7b'

mod "puppetlabs/concat", '1.2.5'


mod 'rtyler/groovy', '1.0.3'
# Dependency of `groovy
mod 'nanliu/staging', '0.4.0'


# For managing server-side ssh configuration options
mod 'saz/ssh', '2.3.6'

mod 'puppetlabs/lvm', '0.3.2'
mod 'datadog/datadog_agent', '1.6.0'

# Used for grabbing certificates for jenkins.io
mod 'danzilio/letsencrypt', '1.0.0'
