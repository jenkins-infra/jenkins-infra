#
# Defines an census server for serving census datasets
#
class profile::census (
  Stdlib::Absolutepath $home_dir = '/srv/census',
  String               $user     = 'census',
  String               $group    = 'census',
) {
  include stdlib # Required to allow using stlib methods and custom datatypes
  # volume configuration is in hiera
  include lvm
  include profile::apachemisc

  $docroot = "${home_dir}/census"

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
    servername                   => 'census.jenkins.io',
    use_servername_for_filenames => true,
    use_port_for_filenames       => true,
    vhost_name                   => '*',
    port                         => 80,
    docroot                      => $docroot,
    access_log_pipe              => "|/usr/bin/rotatelogs -p ${profile::apachemisc::compress_rotatelogs_path} /var/log/apache2/census.jenkins.io/access.log.%Y%m%d%H%M%S 604800",
    error_log_pipe               => "|/usr/bin/rotatelogs -p ${profile::apachemisc::compress_rotatelogs_path} /var/log/apache2/census.jenkins.io/error.log.%Y%m%d%H%M%S 604800",
    options                      => ['FollowSymLinks', 'MultiViews', 'Indexes'],
    override                     => ['All'],
    notify                       => Service['apache2'],
    require                      => [
      File['/var/log/apache2/census.jenkins.io'],
      File[$docroot],
      Class['lvm']
    ],
  }
}
