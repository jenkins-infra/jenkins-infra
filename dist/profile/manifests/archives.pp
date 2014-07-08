#
# Defines an archive server for serving all the archived historical releases
#
class profile::archives{
  # create volume for storage
  physical_volume { '/dev/xvdb':
    ensure => present,
  }

  volume_group { 'archives':
    ensure           => present,
    physical_volumes => '/dev/xvdb',
  }

  logical_volume { 'releases':
    ensure       => present,
    volume_group => 'archives',
    size         => '100G',
  }

  filesystem { '/dev/archives/releases':
    ensure  => present,
    fs_type => 'ext3',
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
