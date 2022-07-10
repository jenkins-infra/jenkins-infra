#
# This profile configures letsencrypt on the host it's applied to
class profile::letsencrypt {
  class { 'letsencrypt':
    config         => {
      email  => lookup('letsencrypt::config::email'),
      server => lookup('letsencrypt::config::server'),
    },
    package_ensure => 'latest',
    configure_epel => false,
  }

  package { 'python3-certbot-apache':
    ensure => present,
  }

  # This definition is removed in favor of "renew_cron_ensure" set to present
  cron { 'letsencrypt-renew-reload':
    ensure  => absent,
    command => '/opt/letsencrypt/letsencrypt-auto renew --quiet --renew-hook="service apache2 reload"',
    hour    => 12,
    user    => 'root',
  }
}
