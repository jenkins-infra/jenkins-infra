#
# Profile to provision the necessary "usage" host setup
#
# A "usage" host is one that will receive anonymized and encrypted usage data
# from active and cnofigured Jenkins installations around the world.
#
# This usage information is then processed and ultimately finds its way into
# our "census" data
class profile::usage(
  $docroot    = '/var/www/usage.jenkins.io',
  $usage_fqdn = 'usage.jenkins.io',
  $home_dir   = '/var/log/usage-stats',
  $user       = 'usagestats',
  $group      = 'usagestats',
  $ssh_keys   = undef,
) {
  include ::stdlib
  include ::apache
  include profile::accounts
  include profile::apachemisc
  include profile::firewall

  validate_string($docroot)
  validate_string($usage_fqdn)
  validate_string($user)
  validate_string($group)
  validate_string($home_dir)


  if $ssh_keys != undef {
    validate_hash($ssh_keys)
  }

  ## Download/Upload usage data permissions
  ############################
  ## The usage stats are (currently) downloaded by a machine at Kohsuke's house
  ## where they are decrypted and then re-uploaded to this host for processing
  ############################

  # This wrapper script will not be necessary after Kohsuke's scripts migrate
  # away from using his own user
  file { '/home/kohsuke/sudo-rsync':
    ensure  => file,
    mode    => '0755',
    content => '#!/bin/sh
exec rsync "$@"',
    require => User['kohsuke'],
  }

  group { $group :
    ensure => present,
  }

  account { $user:
    manage_home    => true,
    create_group   => false,
    # Ensure that our homedir is group-readable/writable so that legacy users
    # (e.g. the `kohsuke` user) can write into it properly
    home_dir_perms => '0775',
    home_dir       => $home_dir,
    gid            => $group,
    ssh_keys       => $ssh_keys,
    require        => Group[$group],
  }

  exec { 'add-kohsuke-to-usage-group':
    unless  => 'grep -q "usagestats\\S*kohsuke" /etc/group',
    command => "usermod -aG ${group} kohsuke",
    path    => ['/sbin', '/bin', '/usr/sbin'],
    require => [
      Group[$group],
      User['kohsuke'],
    ],
  }
  ##

  $apache_log_dir = "/var/log/apache2/${usage_fqdn}"

  file { $docroot:
    ensure  => directory,
    require => Package['httpd'],
  }

  file { 'usage-stats.js':
    ensure  => file,
    path    => "${docroot}/usage-stats.js",
    content => '// usage statistics submission comes to this URL',
    require => File[$docroot],
  }

  file { $apache_log_dir:
    ensure => directory,
  }

  apache::vhost { $usage_fqdn:
    port            => 443,
    # We need FollowSymLinks to ensure our fallback for old APT clients works
    # properly, see debian's htaccess file for more
    options         => 'Indexes FollowSymLinks MultiViews',
    override        => ['All'],
    ssl             => true,
    docroot         => $docroot,
    error_log_file  => "${usage_fqdn}/error.log",
    access_log_pipe => "|/usr/bin/rotatelogs ${apache_log_dir}/access.log.%Y%m%d%H%M%S 604800",
    require         => File[$docroot],
  }

  apache::vhost { "${usage_fqdn} unsecured":
    servername      => $usage_fqdn,
    port            => 80,
    # We need FollowSymLinks to ensure our fallback for old APT clients works
    # properly, see debian's htaccess file for more
    options         => 'Indexes FollowSymLinks MultiViews',
    override        => ['All'],
    docroot         => $docroot,
    error_log_file  => "${usage_fqdn}/error_nonssl.log",
    access_log_pipe => "|/usr/bin/rotatelogs ${apache_log_dir}/access_nonssl.log.%Y%m%d%H%M%S 604800",
    require         => File[$docroot],
  }
}
