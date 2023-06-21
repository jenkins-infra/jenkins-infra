#
# Profile for managing basics of docker installation/configuration
class profile::docker {
  class { 'docker':
  }

  if ($facts['os']['architecture'] == 'aarch64') {
    # 'https://github.com/puppetlabs/puppetlabs-docker/issues/494 (even with APT module at 8.4.1)
    Apt::Source <| architecture == 'aarch64' |> { architecture => 'arm64' }
  }

  include datadog_agent::integrations::docker_daemon

  # Restrict UDP dogStatsD traffic only from loopback or docker0
  firewall {
    '901 Drop all non local dogStatsD UDP/8125 inbound requests':
      proto   => 'udp',
      dport   => 8125,
      iniface => ['! lo', '! docker0'],
      action  => 'drop',
  }

  # Ensure that the datadog user has the right group to access docker
  user { $datadog_agent::params::dd_user:
    ensure  => present,
    groups  => ['docker'],
    require => Class['docker'],
    before  => Class['datadog_agent::integrations::docker_daemon'],
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

  file { '/etc/docker':
    ensure  => directory,
    mode    => '0700',
    recurse => true,
  }

  file { '/etc/docker/daemon.json':
    ensure  => file,
    require => File['/etc/docker'],
    source  => "puppet:///modules/${module_name}/docker/daemon.json",
    mode    => '0600',
    notify  => Service['docker'],
  }

  package { 'cron':
    ensure => installed,
  }

  cron { 'docker-system-prune':
    # Override the content of the log file to avoid heavy files not rotated in 2-3 years.
    command => "bash -c 'date && docker system prune --volumes --force' >/var/log/docker-system-prune.log 2>&1",
    user    => 'root',
    hour    => 2,
    minute  => 0,
    require => [Class['docker'],Package['cron']],
  }
}
