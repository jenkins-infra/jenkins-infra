#
# Role for a machine acting as an updates.jenkins.io host
class role::updates {
  include profile::base
  include profile::updatesite

  package { 'lvm2':
    ensure => present,
    before => [
      Class['lvm'],
    ],
  }

  # volume configuration is in hiera
  include lvm
}
