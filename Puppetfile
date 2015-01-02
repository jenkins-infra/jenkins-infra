forge "http://forge.puppetlabs.com"

# Install and manage r10k
mod "zack/r10k", '1.0.2'

# Deps for zack/r10k
mod "puppetlabs/stdlib", '4.4.0'

mod 'puppetlabs/ruby', '0.2.1'
mod "puppetlabs/gcc", '0.2.0'
mod "puppetlabs/pe_gem", '0.0.1'
mod "mhuffnagle/make", '0.0.2'
mod "puppetlabs/inifile", '1.0.3'
mod "puppetlabs/vcsrepo", '1.1.0'
mod "puppetlabs/git", '0.2.0'
mod "gentoo/portage", '2.2.0-rc1'

# Used for setting up ntp daemons on all machines to have a correct time
mod "puppetlabs/ntp", '3.1.2'

# Module for managing sudoers across all machines
mod 'saz/sudo', '3.0.6'

# Needed for managing firewall rules
mod 'puppetlabs/firewall', '1.1.3'

# Needed for managing .yaml files from within Puppet
mod 'reidmv/yamlfile'
# Needed by `yamlfile`
mod 'adrien/filemapper'

mod 'docker', :git => 'git://github.com/jenkins-infra/garethr-docker.git',
              :ref => '82fd950'

# Deps for docker
mod 'puppetlabs/apt', '1.6.0'
mod 'stahnma/epel', '0.0.6'

# Dependencies for the Puppet IRC report processor, using our forked version
# which properly compiles and runs on PE
mod 'irc', :git => 'git://github.com/jenkins-infra/puppet-irc.git',
           :ref => '265c24b'

# Needed for managing our accounts in hiera, this fork contains the pull
# request which adds support for multiple SSH keys:
# <https://github.com/torrancew/puppet-account/pull/18>
mod 'account', :git => 'git://github.com/jenkins-infra/puppet-account.git',
               :ref => '03280b8'

mod 'jenkins_keys',
  :git => 'git@github.com:rtyler/jenkins-keys.git',
  :ref => '4a65ae2'

# Apache and its dependencies
mod "puppetlabs/apache", '1.1.1'
# Used internally to gzip compress rotated logs
mod 'apache-logcompressor', :git => 'git://github.com/jenkins-infra/puppet-apache-logcompressor.git'
mod "puppetlabs/concat", '1.0.4'


mod 'rtyler/groovy', '1.0.3'
# Dependency of `groovy

mod 'nanliu/staging', '1.0.2'

# For managing server-side ssh configuration options
mod 'saz/ssh', '2.3.6'

mod 'puppetlabs/lvm', '0.3.3'

# for jira
mod 'mkrakowitzer/jira', '1.1.3'
# and deps for it
mod 'mkrakowitzer/deploy', '0.0.3'
mod 'nanliu/staging', '1.0.2'
