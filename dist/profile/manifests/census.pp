#
# Defines an census server for serving census datasets
#
class profile::census(
  $home_dir = '/srv/census',
  $user     = 'census',
  $group    = 'census',
) {
  include ::stdlib
  # volume configuration is in hiera
  include ::lvm
  include profile::apachemisc

  $docroot = "${home_dir}/census"

  if str2bool($::vagrant) {
    # during serverspec test, fake /dev/xvdb by a loopback device
    exec { 'create /tmp/xvdb':
      command => 'dd if=/dev/zero of=/tmp/xvdb bs=1M count=16; losetup /dev/loop0; losetup /dev/loop0 /tmp/xvdb',
      unless  => 'test -f /tmp/xvdb',
      path    => '/usr/bin:/usr/sbin:/bin:/sbin',
      before  => Physical_volume['/dev/loop0'],
    }
  }

  package { 'lvm2':
    ensure => present,
  }

  group { $group:
    ensure => present,
  }

  account { $user:
    manage_home    => true,
    create_group   => false,
    home_dir_perms => '0755',
    home_dir       => $home_dir,
    gid            => $group,
    require        => Group[$group],
  }

  file { $docroot:
    ensure  => directory,
    owner   => $user,
    mode    => '0755',
    require => Account[$user],
  }

  ssh_authorized_key { 'usage':
    type    => 'ssh-rsa',
    user    => $user,
    key     => lookup('usage_ssh_pubkey'),
    require => File["${home_dir}/.ssh"],
  }

  file { '/var/log/apache2/census.jenkins.io':
    ensure => directory,
  }

  apache::vhost { 'census.jenkins.io':
    vhost_name      => '*',
    port            => '80',
    docroot         => $docroot,
    access_log_pipe => '|/usr/bin/rotatelogs /var/log/apache2/census.jenkins.io/access.log.%Y%m%d%H%M%S 604800',
    error_log_pipe  => '|/usr/bin/rotatelogs /var/log/apache2/census.jenkins.io/error.log.%Y%m%d%H%M%S 604800',
    options         => ['FollowSymLinks', 'MultiViews', 'Indexes'],
    override        => ['All'],
    notify          => Service['apache2'],
    require         => [File['/var/log/apache2/census.jenkins.io'],
                        File[$docroot],
                        Mount[$home_dir]],
  }
}
