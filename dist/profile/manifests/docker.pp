#
# Profile for managing basics of docker installation/configuration
class profile::docker {
  class { '::docker':
    # Disabling the management of the kernel, since we have to pre-install
    # kernel modules on Ubuntu 12.04 LTS and restart the host machine anyways
    manage_kernel => false,
  }
}
