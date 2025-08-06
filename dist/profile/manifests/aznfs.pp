# Profile to ensure `azcopy` and `az-cli` are installed, up-to-date and set up (SAS token generation, etc.)
class profile::aznfs (
  Array $mounts                       = [],
) {
  include profile::aptmicrosoftprod

  package { 'nfs-common':
    ensure  => 'latest',
    require => Class['apt::update'],
  }

  package { 'aznfs':
    ensure  => 'latest',
    require => Class['apt::update'],
  }

  $mounts.each | $aznfs_mount | {
    mount { $aznfs_mount['mountpoint']:
      ensure  => 'mounted',
      atboot  => 'true',
      device  => $aznfs_mount['url'],
      fstype  => 'aznfs',
      options => 'vers=4,minorversion=1,_netdev,nofail,sec=sys,nconnect=4',
    }
  }
}
