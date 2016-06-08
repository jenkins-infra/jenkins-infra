#
# Defines an census server for serving census datasets
#
class profile::census(
  $census_dir = '/srv/census',
  $conf_dir   = '/etc/census',
  $user       = 'www-data',
) {
  include ::stdlib
  # volume configuration is in hiera
  include ::lvm
  include profile::apachemisc

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

  file { $census_dir:
    ensure  => directory,
    owner   => $user,
    require => [Package['httpd'],
                Mount[$census_dir]],
  }

  file { $conf_dir:
    ensure => directory,
    owner  => $user,
    mode   => '0750',
  }

  # the www-data user's home dir is determined by the native package
  $home_dir = '/var/www'

  file { "${home_dir}/.ssh":
    ensure  => directory,
    owner   => $user,
    mode    => '0700',
    require => File[$home_dir],
  }

  ensure_resource('file', $home_dir, {
    'ensure' => 'directory',
    'owner'  => $user,
  })

  ssh_authorized_key { 'usage':
    type    => 'ssh-rsa',
    user    => $user,
    key     => hiera('usage_ssh_pubkey'),
    require => File["${home_dir}/.ssh"],
  }

  file { "${conf_dir}/anonymized-passwords":
    ensure  => present,
    owner   => $user,
    mode    => '0600',
    source  => "puppet:///modules/${module_name}/census/anonymized-passwords",
    require => File[$conf_dir],
  }

  file { "${conf_dir}/monthly-passwords":
    ensure  => present,
    owner   => $user,
    mode    => '0600',
    source  => "puppet:///modules/${module_name}/census/monthly-passwords",
    require => File[$conf_dir],
  }


  file { '/var/log/apache2/census.jenkins.io':
    ensure => directory,
  }

  apache::vhost { 'census.jenkins.io':
    vhost_name      => '*',
    port            => '80',
    docroot         => $census_dir,
    access_log      => false,
    error_log_file  => 'census.jenkins.io/error.log',
    log_level       => 'warn',
    custom_fragment => template("${module_name}/census/vhost.conf"),
    options         => ['FollowSymLinks', 'MultiViews', 'Indexes'],
    notify          => Service['apache2'],
    require         => [File['/var/log/apache2/census.jenkins.io'],
                        File["${conf_dir}/monthly-passwords"],
                        File["${conf_dir}/anonymized-passwords"],
                        Mount[$census_dir]],
  }
}
