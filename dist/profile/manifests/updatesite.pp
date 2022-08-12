#
# This updatesite profile is responsible for provisioning what is generally
# know as updates.jenkins.io and allows for the publication of our
# update-center generation, see:
# <https://github.com/jenkinsci/backend-update-center2>
#
class profile::updatesite (
  $docroot = '/var/www/updates.jenkins.io',
  $ssh_pubkey = undef,
) {
  include stdlib
  include apache

  include profile::apachemisc
  include profile::firewall
  include profile::letsencrypt

  $update_fqdn = 'updates.jenkins.io'
  $apache_log_dir = "/var/log/apache2/${update_fqdn}"
  $apache_legacy_log_dir = '/var/log/apache2/updates.jenkins-ci.org'

  # We need a shell for now
  # https://issues.jenkins-ci.org/browse/INFRA-657
  User <| title == 'www-data' |> {
    shell => '/bin/bash',
  }
  file { '/var/www':
    ensure => directory,
    mode   => '0755',
  }

  file { [$apache_log_dir, $docroot, $apache_legacy_log_dir,]:
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

    access_log_pipe              => "|/usr/bin/rotatelogs -t ${apache_log_dir}/access.log.%Y%m%d%H%M%S 604800",
    error_log_pipe               => "|/usr/bin/rotatelogs -t ${apache_log_dir}/error.log.%Y%m%d%H%M%S 604800",
  }

  apache::vhost { "${update_fqdn} unsecured":
    servername                   => $update_fqdn,
    use_servername_for_filenames => true,
    use_port_for_filenames       => true,
    port                         => 80,
    docroot                      => $docroot,
    override                     => ['All'],

    access_log_pipe              => "|/usr/bin/rotatelogs -t ${apache_log_dir}/access_unsecured.log.%Y%m%d%H%M%S 604800",
    error_log_pipe               => "|/usr/bin/rotatelogs -t ${apache_log_dir}/error_unsecured.log.%Y%m%d%H%M%S 604800",
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

    access_log_pipe              => "|/usr/bin/rotatelogs -t ${apache_legacy_log_dir}/access.log.%Y%m%d%H%M%S 604800",
    error_log_pipe               => "|/usr/bin/rotatelogs -t ${apache_legacy_log_dir}/error.log.%Y%m%d%H%M%S 604800",
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

    access_log_pipe              => "|/usr/bin/rotatelogs -t ${apache_legacy_log_dir}/access_unsecured.log.%Y%m%d%H%M%S 604800",
    error_log_pipe               => "|/usr/bin/rotatelogs -t ${apache_legacy_log_dir}/error_unsecured.log.%Y%m%d%H%M%S 604800",
    require                      => Apache::Vhost['updates.jenkins-ci.org'],
  }

  ##################################
  ##################################

  if $ssh_pubkey {
    validate_string($ssh_pubkey)

    file { '/var/www/.ssh':
      ensure => directory,
      mode   => '0700',
      owner  => 'www-data',
      group  => 'www-data',
    }

    ssh_authorized_key { 'updatesite-key':
      ensure  => present,
      user    => 'www-data',
      type    => 'ssh-rsa',
      key     => $ssh_pubkey,
      require => File['/var/www/.ssh'],
    }

    # If we're managing an ssh_authorized_key, then we should purge anything
    # else for safety's sake
    User <| title == 'www-data' |> {
      managehome     => true,
      home           => '/var/www',
      purge_ssh_keys => true,
    }
  }

  # We can only acquire certs in production due to the way the letsencrypt
  # challenge process works
  if (($environment == 'production') and ($facts['kind'] != 'vagrant')) {
    [$update_fqdn, 'updates.jenkins-ci.org'].each |String $domain| {
      letsencrypt::certonly { $domain:
        domains     => [$domain],
        plugin      => 'apache',
        manage_cron => true,
      }

      Apache::Vhost <| title == $domain |> {
        ssl_key   => "/etc/letsencrypt/live/${domain}/privkey.pem",
        # When Apache is upgraded to >= 2.4.8 this should be changed to
        # fullchain.pem
        ssl_cert  => "/etc/letsencrypt/live/${domain}/cert.pem",
        ssl_chain => "/etc/letsencrypt/live/${domain}/chain.pem",
      }
    }
  }
}
