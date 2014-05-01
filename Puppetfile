forge "http://forge.puppetlabs.com"

# Install and manage r10k
mod "zack/r10k", '1.0.2'

# Deps for zack/r10k
# We are tracking stdlib from git because the puppet module tool 
# is getting in the way when we want to upgrade newer than the 
# supported module version
mod "stdlib", :git => 'git@github.com:puppetlabs/puppetlabs-stdlib.git',
  :ref => '4.1.0'

mod "puppetlabs/ruby", '0.1.0'
mod "puppetlabs/gcc", '0.1.0'
mod "puppetlabs/pe_gem", '0.0.1'
mod "mhuffnagle/make", '0.0.2'
mod "puppetlabs/inifile", '1.0.3'
mod "puppetlabs/vcsrepo", '0.2.0'
mod "puppetlabs/git", '0.0.3'
mod "gentoo/portage", '2.2.0-rc1'

# Used for setting up ntp daemons on all machines to have a correct time
mod "puppetlabs/ntp", '3.0.3'

# Module for managing sudoers across all machines
mod 'saz/sudo', '3.0.6'

# Needed for managing .yaml files from within Puppet
mod 'reidmv/yamlfile'
# Needed by `yamlfile`
mod 'adrien/filemapper'

mod 'garethr/docker', '0.13.0'

# Deps for docker
mod 'puppetlabs/apt', '1.4.2'
mod 'stahnma/epel', '0.0.6'

# Dependencies for the Puppet IRC report processor, using our forked version
# which properly compiles and runs on PE
mod 'irc', :git => 'git://github.com/jenkins-infra/puppet-irc.git',
           :ref => 'ca69ffa'

# Needed for managing our accounts in hiera, this fork contains the pull
# request which adds support for multiple SSH keys:
# <https://github.com/torrancew/puppet-account/pull/18>
mod 'account', :git => 'git://github.com/jenkins-infra/puppet-account.git',
               :ref => '03280b8'

mod 'jenkins_keys',
  :git => 'git@github.com:rtyler/jenkins-keys.git'
