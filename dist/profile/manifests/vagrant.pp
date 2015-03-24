#
# Vagrant profile for capturing some of the spceifics we need for Vagrant boxes
# to provision cleanly
class profile::vagrant {
  include sudo

  # AWS Ubuntu images have an `ubuntu` default user which Vagrant will use for
  # provisioning
  sudo::conf { 'ubuntu':
    priority => '10',
    content  => 'ubuntu ALL=(ALL) NOPASSWD: ALL',
  }
}
