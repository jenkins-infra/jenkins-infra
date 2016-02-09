#
# Manage an OpenLDAP authentication service
class profile::ldap {
  package { 'slapd':
    ensure => present,
  }

  service { 'slapd':
    ensure     => running,
    hasrestart => true,
    enable     => true,
  }

  file { '/etc/default/slapd':
    source => "puppet:///modules/${module_name}/slapd.defaults",
    notify => Service[slapd],
  }
}
