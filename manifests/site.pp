## site.pp ##

## Active Configurations ##

# PRIMARY FILEBUCKET
# This configures puppet agent and puppet inspect to back up file contents when
# they run. The Puppet Enterprise console needs this to display file contents
# and differences.

# Define filebucket 'main':
filebucket { 'main':
  server => 'puppet.jenkins.io',
  path   => false,
}

# Make filebucket 'main' the default backup location for all File resources:
File { backup => 'main' }

# DEFAULT NODE
# Node definitions in this file are merged with node data from the console. See
# http://docs.puppetlabs.com/guides/language_guide.html#nodes for more on
# node definitions.

# The default node definition matches any node lacking a more specific node
# definition. If there are no other nodes in this file, classes declared here
# will be included in every node's catalog, *in addition* to any classes
# specified in the console for that node.

node default {
  include profile::base
}

## DigitalOcean VM
node 'archives.do.jenkins.io' {
  mount { '/srv':
    ensure => 'mounted',
    atboot => 'true',
    device => 'UUID=2bfde305-641d-4e6b-9376-96cdb1919860',
    fstype => 'ext4',
  }
  include role::archives
}
node 'usage.do.jenkins.io' {
  mount { '/srv/usage':
    ensure => 'mounted',
    atboot => 'true',
    device => 'UUID=5e21c9f9-d2a2-422b-90e9-433d9ba42de1',
    fstype => 'ext4',
  }
  include role::usage
}

node 'census.do.jenkins.io' {
  mount { '/srv/census':
    ensure => 'mounted',
    atboot => 'true',
    device => 'UUID=94f8a328-f89b-4fa2-8209-ff6556299026',
    fstype => 'ext4',
  }
  include role::census
}

node 'pkg' {
  include role::pkg
}

node 'aws.ci.jenkins.io' {
  include role::jenkins::controller
}

node 'controller.cert.ci.jenkins.io' {
  mount { '/var/lib/jenkins':
    ensure => 'mounted',
    atboot => 'true',
    device => 'UUID=afa01d2f-c643-4b0f-a917-66fedaee9325',
    fstype => 'ext4',
  }
  include role::privateci
}

node 'private.vpn.jenkins.io' {
  sshkeyman::hostkey { ['private.vpn.jenkins.io']: }
  include role::openvpn
}

node 'agent.trusted.ci.jenkins.io' {
  mount { '/home/jenkins':
    ensure => 'mounted',
    atboot => 'true',
    device => 'UUID=909588b9-9f20-43cf-8918-e390585789d4',
    fstype => 'ext4',
  }
  include role::updatecenter
  include profile::aznfs
}

node 'controller.trusted.ci.jenkins.io' {
  mount { '/var/lib/jenkins':
    ensure => 'mounted',
    atboot => 'true',
    device => 'UUID=60de6f1a-4c88-47c6-928d-4dcb55e02f21',
    fstype => 'ext4',
  }
  include role::jenkins::controller
}
