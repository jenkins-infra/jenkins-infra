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

  # Cleanup non-dangling (docker system prune already do this) but non-used images
  # This cleanup is safe: if you do not use the '-f, --force' flag on `docker image`,
  # then Docker refuses to remove running container's images with 'image is being used by running container' message
  cron { 'docker-images-cleanup':
    # Override the content of the log file to avoid heavy files not rotated in 2-3 years.
    command => "bash -c 'date &&  docker image ls -q | xargs docker image rm' >/var/log/docker-images-cleanup.log 2>&1",
    user    => 'root',
    hour    => 3,
    minute  => 0,
    require => [Class['docker'],Package['cron']],
  }
}
