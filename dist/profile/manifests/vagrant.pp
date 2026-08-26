#
# Vagrant profile for capturing some of the spceifics we need for Vagrant boxes
# to pvoision cleanly
class profile::vagrant {
  Exec { '/usr/bin/apt-get update --quiet':,
  }
  include sudo

  # Vagrant defines a default user `vagrant` which should have passwordless sudo permission
  sudo::conf { 'vagrant':
    ensure   => file,
    priority => '10',
    content  => 'vagrant ALL=(ALL) NOPASSWD: ALL',
  }
}
