#
# Defines an archive server for serving all the archived historical releases
#
class profile::archives{

  package { 'lvm2':
    ensure => present,
  }

  # create volume for storage
  physical_volume { '/dev/xvdb':
    ensure  => present,
    require => Package['lvm2'],
  }

  volume_group { 'archives':
    ensure           => present,
    physical_volumes => '/dev/xvdb',
    require      => Physical_volume['/dev/xvdb']
  }

  logical_volume { 'releases':
    ensure       => present,
    volume_group => 'archives',
    size         => '100G',
    require      => Volume_group['archives']
  }

  filesystem { '/dev/archives/releases':
    ensure  => present,
    fs_type => 'ext3',
    require => Logical_volume['releases'],
  }

  file { '/srv':
    ensure  => directory,
  }

  file { '/srv/releases':
    ensure  => directory,
  }

  mount { '/srv/releases':
    device   => '/dev/archives/releases',
    require  => [File['/srv/releases'],Filesystem['/dev/archives/releases']],
  }
}
