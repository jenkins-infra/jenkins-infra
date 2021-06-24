#
# Profile for managing basics of docker installation/configuration
class profile::docker {
  class { '::docker':
  }

  include datadog_agent::integrations::docker_daemon

  # Ensure that the datadog user has the right group to access docker
  user { $datadog_agent::params::dd_user:
    ensure  => present,
    groups  => ['docker'],
    require => Class['::docker'],
    before  => Class['datadog_agent::integrations::docker_daemon']
  }

  firewall { '010 allow inter-docker traffic':
    # traffic within docker is OK
    iniface => 'docker0',
    action  => 'accept',
  }

  ['lxcfs', 'lxd', 'lxd-client', 'liblxc-common', 'liblxc1'].each | $package | {
    package { $package:
      ensure => 'purged',
    }
  }

  file { '/etc/docker/daemon.json':
    ensure => present,
    source => "puppet:///modules/${module_name}/docker/daemon.json",
    mode   => '0644',
    notify => Service['docker'],
  }
}
