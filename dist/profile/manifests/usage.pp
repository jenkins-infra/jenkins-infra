#
# Profile to provision the necessary "usage" host setup
#
# A "usage" host is one that will receive anonymized and encrypted usage data
# from active and cnofigured Jenkins installations around the world.
#
# This usage information is then processed and ultimately finds its way into
# our "census" data
class profile::usage (
  Stdlib::Absolutepath $docroot    = '/var/www/usage.jenkins.io',
  Stdlib::Absolutepath $home_dir   = '/srv/bigger-usage',
  Stdlib::Fqdn         $usage_fqdn = 'usage.jenkins.io',
  String               $user       = 'usagestats',
  String               $group      = 'usagestats',
  Hash                 $ssh_keys   = undef,
) {
  include stdlib # Required to allow using stlib methods and custom datatypes
  include apache
  # volume configuration is in hiera
  include lvm
  include profile::accounts
  include profile::apachemisc
  include profile::firewall
  include profile::letsencrypt

  package { 'lvm2':
    ensure => present,
  }

  $mounted_logs_dir = "${home_dir}/apache-logs"
  $mounted_stats_dir = "${home_dir}/usage-stats"

  file { [$mounted_logs_dir, $mounted_stats_dir]:
    ensure => directory,
    owner  => $user,
    group  => $group,
    mode   => '0755',
  }
  ############################

  ## Download/Upload usage data permissions
  ############################
  ## The usage stats are (currently) downloaded by a machine at Kohsuke's house
  ## where they are decrypted and then re-uploaded to this host for processing
  ############################

  group { $group :
    ensure => present,
  }

  account { $user:
    manage_home    => true,
    create_group   => false,
    home_dir_perms => '0755',
    home_dir       => $home_dir,
    gid            => $group,
    ssh_keys       => $ssh_keys,
    require        => Group[$group],
  }

  ssh_authorized_key { 'usage':
    type    => 'ssh-rsa',
    user    => $user,
    key     => lookup('usage_ssh_pubkey'),
    require => Account[$user],
  }
  ##

  $apache_log_dir = "/var/log/apache2/${usage_fqdn}"

  file { $docroot:
    ensure  => directory,
    owner   => 'www-data',
    group   => $group,
    mode    => '0775',
    require => Package['httpd'],
  }

  file { 'usage-stats.js':
    ensure  => file,
    path    => "${docroot}/usage-stats.js",
    content => '// usage statistics submission comes to this URL',
    owner   => 'www-data',
    group   => $group,
    mode    => '0775',
    require => File[$docroot],
  }

  file { $apache_log_dir:
    ensure  => link,
    group   => $group,
    target  => $mounted_logs_dir,
    require => [
      Package['httpd'],
      File[$mounted_logs_dir],
    ],
  }

  ## Legacy mappings
  ############################
  file { '/var/log/apache2/usage.jenkins-ci.org':
    ensure  => link,
    group   => $group,
    target  => $apache_log_dir,
    require => File[$apache_log_dir],
  }

  file { '/var/log/usage-stats':
    ensure  => link,
    target  => $mounted_stats_dir,
    require => File[$mounted_stats_dir],
  }
  ############################

  apache::vhost { $usage_fqdn:
    servername                   => $usage_fqdn,
    port                         => 443,
    use_servername_for_filenames => true,
    use_port_for_filenames       => true,
    # We need FollowSymLinks to ensure our fallback for old APT clients works
    # properly, see debian's htaccess file for more
    options                      => 'Indexes FollowSymLinks MultiViews',
    override                     => ['All'],
    ssl                          => true,
    docroot                      => $docroot,

    access_log_pipe              => "|/usr/bin/rotatelogs ${apache_log_dir}/access_${usage_fqdn}.log.%Y%m%d%H%M%S 86400",
    error_log_pipe               => "|/usr/bin/rotatelogs ${apache_log_dir}/error_${usage_fqdn}.log.%Y%m%d%H%M%S 86400",
    require                      => [
      File[$docroot],
      File[$apache_log_dir],
    ],
  }

  apache::vhost { "${usage_fqdn} unsecured":
    servername                   => $usage_fqdn,
    serveraliases                => [
      'usage.jenkins-ci.org',
    ],
    port                         => 80,
    use_servername_for_filenames => true,
    use_port_for_filenames       => true,
    # We need FollowSymLinks to ensure our fallback for old APT clients works
    # properly, see debian's htaccess file for more
    options                      => 'Indexes FollowSymLinks MultiViews',
    override                     => ['All'],
    docroot                      => $docroot,
    access_log_pipe              => "|/usr/bin/rotatelogs ${apache_log_dir}/access_${usage_fqdn}_unsecured.log.%Y%m%d%H%M%S 86400",
    error_log_pipe               => "|/usr/bin/rotatelogs ${apache_log_dir}/error_${usage_fqdn}_unsecured.log.%Y%m%d%H%M%S 86400",
    require                      => [
      File[$docroot],
      File[$apache_log_dir],
    ],
  }

  # Legacy (usage.jenkins-ci.org) SSL host with the legacy SSL key
  file { '/etc/apache2/legacy_cert.key':
    ensure  => file,
    content => lookup('ssl_legacy_key'),
    require => Package['httpd'],
  }

  file { '/etc/apache2/legacy_chain.crt':
    ensure  => file,
    content => lookup('ssl_legacy_chain'),
    require => Package['httpd'],
  }
  file { '/etc/apache2/legacy_cert.crt':
    ensure  => file,
    content => lookup('ssl_legacy_cert'),
    require => Package['httpd'],
  }

  # Since usage stats are reported via the browser instead of the Jenkins
  # controller itself, we can just redirect from usage.jenkins-ci.org to
  # usage.jenkins.io and let usage.jenkins.io log the access
  # https://github.com/jenkinsci/jenkins/blob/5416411/core/src/main/resources/hudson/model/UsageStatistics/footer.jelly
  apache::vhost { 'usage.jenkins-ci.org':
    servername                   => 'usage.jenkins-ci.org',
    docroot                      => $docroot,
    port                         => 443,
    use_servername_for_filenames => true,
    use_port_for_filenames       => true,
    ssl                          => true,
    ssl_key                      => '/etc/apache2/legacy_cert.key',
    ssl_chain                    => '/etc/apache2/legacy_chain.crt',
    ssl_cert                     => '/etc/apache2/legacy_cert.crt',
    override                     => ['All'],
    redirect_status              => 'permanent',
    redirect_dest                => 'https://usage.jenkins.io/',
    # Blackhole all these redirect logs https://issues.jenkins-ci.org/browse/INFRA-739

    access_log_file              => '/dev/null',
    require                      => [
      File['/etc/apache2/legacy_cert.crt'],
      File['/etc/apache2/legacy_cert.key'],
      File['/etc/apache2/legacy_chain.crt'],
      Apache::Vhost[$usage_fqdn],
    ],
  }

  # We can only acquire certs in production due to the way the letsencrypt
  # challenge process works
  if (($environment == 'production') and ($facts['vagrant'] != '1')) {
    letsencrypt::certonly { $usage_fqdn:
      domains => [$usage_fqdn],
      plugin  => 'apache',
    }

    Apache::Vhost <| title == $usage_fqdn |> {
      ssl_key   => "/etc/letsencrypt/live/${usage_fqdn}/privkey.pem",
      ssl_cert  => "/etc/letsencrypt/live/${usage_fqdn}/fullchain.pem",
    }
  }
}
