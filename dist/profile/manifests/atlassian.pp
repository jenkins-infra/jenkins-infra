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

  sudo::conf { $group_name:
    priority => 10,
    content  => "%${group_name} ALL=(ALL) NOPASSWD: /usr/sbin/service,/usr/bin/docker",
    require  => Group[$group_name],
  }
}
