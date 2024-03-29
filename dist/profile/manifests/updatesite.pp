#
# This updatesite profile is responsible for provisioning what is generally
# know as updates.jenkins.io and allows for the publication of our
# update-center generation, see:
# <https://github.com/jenkinsci/backend-update-center2>
#
class profile::updatesite (
  Stdlib::Absolutepath $docroot    = '',
  String $mirror_user              = 'mirrorbrain',
  String $www_user                 = 'www-data',
  String $www_common_group         = 'www-data',
) {
  include stdlib # Required to allow using stlib methods and custom datatypes
  include apache

  include profile::apachemisc
  include profile::firewall
  include profile::letsencrypt

  $update_fqdn = 'updates.jenkins.io'
  $apache_log_dir = "/var/log/apache2/${update_fqdn}"
  $apache_legacy_log_dir = '/var/log/apache2/updates.jenkins-ci.org'

  file { '/var/www':
    ensure => directory,
    mode   => '0755',
  }

  file { $docroot:
    ensure  => directory,
    owner   => $mirror_user,
    group   => $www_common_group,
    mode    => '0775',
    require => [File['/var/www']],
  }

  file { [$apache_log_dir, $apache_legacy_log_dir,]:
    ensure => directory,
  }

  apache::vhost { $update_fqdn:
    servername                   => $update_fqdn,
    use_servername_for_filenames => true,
    use_port_for_filenames       => true,
    require                      => [
      File[$docroot],
    ],
    port                         => 443,
    override                     => ['All'],
    ssl                          => true,
    docroot                      => $docroot,

    access_log_pipe              => "|/usr/bin/rotatelogs -p ${profile::apachemisc::compress_rotatelogs_path} -t ${apache_log_dir}/access.log.%Y%m%d%H%M%S 604800",
    error_log_pipe               => "|/usr/bin/rotatelogs -p ${profile::apachemisc::compress_rotatelogs_path} -t ${apache_log_dir}/error.log.%Y%m%d%H%M%S 604800",
  }

  apache::vhost { "${update_fqdn} unsecured":
    servername                   => $update_fqdn,
    use_servername_for_filenames => true,
    use_port_for_filenames       => true,
    port                         => 80,
    docroot                      => $docroot,
    override                     => ['All'],

    access_log_pipe              => "|/usr/bin/rotatelogs -p ${profile::apachemisc::compress_rotatelogs_path} -t ${apache_log_dir}/access_unsecured.log.%Y%m%d%H%M%S 604800",
    error_log_pipe               => "|/usr/bin/rotatelogs -p ${profile::apachemisc::compress_rotatelogs_path} -t ${apache_log_dir}/error_unsecured.log.%Y%m%d%H%M%S 604800",
    require                      => Apache::Vhost[$update_fqdn],
  }

  apache::vhost { 'updates.jenkins-ci.org':
    servername                   => 'updates.jenkins-ci.org',
    use_servername_for_filenames => true,
    use_port_for_filenames       => true,
    docroot                      => $docroot,
    port                         => 443,
    ssl                          => true,
    override                     => ['All'],

    access_log_pipe              => "|/usr/bin/rotatelogs -p ${profile::apachemisc::compress_rotatelogs_path} -t ${apache_legacy_log_dir}/access.log.%Y%m%d%H%M%S 604800",
    error_log_pipe               => "|/usr/bin/rotatelogs -p ${profile::apachemisc::compress_rotatelogs_path} -t ${apache_legacy_log_dir}/error.log.%Y%m%d%H%M%S 604800",
    require                      => [
      File[$apache_legacy_log_dir],
    ],
  }

  apache::vhost { 'updates.jenkins-ci.org unsecured':
    servername                   => 'updates.jenkins-ci.org',
    use_servername_for_filenames => true,
    use_port_for_filenames       => true,
    docroot                      => $docroot,
    port                         => 80,
    override                     => ['All'],

    access_log_pipe              => "|/usr/bin/rotatelogs -p ${profile::apachemisc::compress_rotatelogs_path} -t ${apache_legacy_log_dir}/access_unsecured.log.%Y%m%d%H%M%S 604800",
    error_log_pipe               => "|/usr/bin/rotatelogs -p ${profile::apachemisc::compress_rotatelogs_path} -t ${apache_legacy_log_dir}/error_unsecured.log.%Y%m%d%H%M%S 604800",
    require                      => Apache::Vhost['updates.jenkins-ci.org'],
  }

  # We can only acquire certs in production due to the way the letsencrypt
  # challenge process works
  if (($environment == 'production') and ($facts['vagrant'] != '1')) {
    [$update_fqdn, 'updates.jenkins-ci.org'].each |String $domain| {
      letsencrypt::certonly { $domain:
        domains => [$domain],
        plugin  => 'apache',
      }

      Apache::Vhost <| title == $domain |> {
        ssl_key   => "/etc/letsencrypt/live/${domain}/privkey.pem",
        ssl_cert  => "/etc/letsencrypt/live/${domain}/fullchain.pem",
      }
    }
  }
}
