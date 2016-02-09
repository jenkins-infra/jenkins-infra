#
# Manage an OpenLDAP authentication service
class profile::ldap {
  include ::datadog_agent

  package { 'slapd':
    ensure => present,
  }

  service { 'slapd':
    ensure     => running,
    hasrestart => true,
    enable     => true,
  }

  file { '/etc/default/slapd':
    source => 'puppet:///modules/profile/ldap/slapd.defaults',
    notify => Service[slapd],
  }

  profile::datadog_check { 'ldap-process-check':
    checker => 'process',
    source  => 'puppet:///modules/profile/ldap/process_check.yaml',
  }
}
