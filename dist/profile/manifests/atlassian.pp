#
# Profile containing the basics to support an Atlassian product in our
# infrastructure
#

class profile::atlassian {
  include apache
  include firewall
  include profile::docker
  include sudo

  apache::mod { 'proxy':
  }

  apache::mod { 'proxy_http':
  }

  sudo::conf { 'atlassian-admins':
    priority => 10,
    content  => "%atlassian-admins ALL=(ALL) NOPASSWD: /usr/sbin/service",
    require  => Group[$group_name],
  }
}
