#
# Profile for managing basics of docker installation/configuration
class profile::docker {
  class { '::docker':
    version          => '1.9.1',
    # Disabling the management of the kernel, since we have to pre-install
    # kernel modules on Ubuntu 12.04 LTS and restart the host machine anyways
    manage_kernel    => false,
    extra_parameters => '--storage-driver=aufs',
  }

  include datadog_agent::integrations::docker

  # Ensure that the datadog user has the right group to access docker
  user { $datadog_agent::params::dd_user:
    ensure  => present,
    groups  => ['docker'],
    require => Class['::docker'],
  }

  firewall { '010 allow inter-docker traffic':
    # traffic within docker is OK
    iniface => 'docker0',
    action  => 'accept',
  }
}
