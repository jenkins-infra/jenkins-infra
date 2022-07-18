#
# Defines a updates.jenkins.io server for serving updatesite, aims to deal with volume management
#
class profile::updates() {
  include ::stdlib
  # volume configuration is in hiera
  include ::lvm


  if str2bool($::vagrant) {
    # during serverspec test, fake /dev/oracleoci/oraclevdb by a loopback device
    exec { 'create /tmp/oraclevdb':
      command => 'dd if=/dev/zero of=/tmp/oraclevdb bs=1M count=16; losetup /dev/loop0; losetup /dev/loop0 /tmp/oraclevdb',
      unless  => 'test -f /tmp/oraclevdb',
      path    => '/usr/bin:/usr/sbin:/bin:/sbin',
      before  => Physical_volume['/dev/loop0'],
    }
  }

  package { 'lvm2':
    ensure => present,
  }
}
