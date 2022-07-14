#
# Vagrant profile for capturing some of the spceifics we need for Vagrant boxes
# to pvoision cleanly
class profile::vagrant {
  include sudo

  # Vagrant defines a default user `vagrant` which should have passwordless sudo permission
  sudo::conf { 'vagrant':
    priority => '10',
    content  => 'vagrant ALL=(ALL) NOPASSWD: ALL',
  }
}
