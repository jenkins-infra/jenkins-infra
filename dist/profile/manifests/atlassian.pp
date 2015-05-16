#
# Profile containing the basics to support an Atlassian product in our
# infrastructure
#

class profile::atlassian {
  include apache
  include firewall
  include profile::docker

  apache::mod { 'proxy':
  }

  apache::mod { 'proxy_http':
  }


  group { 'atlassian-admins':
    ensure => present,
  }
}
