#
# Profile containing the basics to support an Atlassian product in our
# infrastructure
#

class profile::atlassian {
  include apache
  include firewall
  include profile::docker
  include sudo

  $group_name = 'atlassian-admins'

  apache::mod { 'proxy':
  }

  apache::mod { 'proxy_http':
  }

  group { $group_name:
    ensure => present,
  }

  sudo::conf { $group_name:
    priority => 10,
    content  => "%${group_name} ALL=(ALL) NOPASSWD: /usr/sbin/service",
    require  => Group[$group_name],
  }
}
