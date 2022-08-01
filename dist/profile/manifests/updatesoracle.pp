#
# Defines specifications for the oracle VM for updates.jenkins.io (oracle.updates.jenkins.io)
#

class profile::updatesoracle (
  Array  $rsync_hosts_allow           = ['pkg.origin.jenkins.io'], # only pkg can update this VM with rsync
  String $rsynched_dir                = '/var/www/updates.jenkins.io',
  String $rsync_motd_file             = '/etc/jenkins.motd',
) {

  # Install Rsync
  #
  # Rsync is needed to synchronise data from pkg machine : updates.jenkins.io to this one (oracle.updates.jenkins.io)
  #
  package { 'rsync':
    ensure => present,
  }

  file { '/etc/rsyncd.conf':
    ensure  => file,
    content => template("${module_name}/oracle.updates.jenkins.io/rsyncd.conf.erb"),
    owner   => 'root',
    mode    => '0600',
    require => Package['rsync'],
  }

  file { $rsync_motd_file:
    ensure  => file,
    source  => "puppet:///modules/${module_name}/updates/jenkins.motd",
    owner   => 'root',
    mode    => '0644',
    require => Package['rsync'],
  }

  service { 'rsync':
    ensure => running,
    enable => true,
  }

  firewall { '100 all inbound rsync':
    proto  => 'tcp',
    dport  => '873',
    action => 'accept',
  }
}
