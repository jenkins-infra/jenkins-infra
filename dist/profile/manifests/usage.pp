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
) {
  include ::stdlib
  include ::apache
  include profile::apachemisc
  include profile::firewall

  validate_string($docroot)
  validate_string($usage_fqdn)

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
