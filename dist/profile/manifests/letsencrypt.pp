#
# This profile configures letsencrypt on the host it's applied to
class profile::letsencrypt {
  class { '::letsencrypt':
    config => {
        email  => lookup('letsencrypt::config::email'),
        server => lookup('letsencrypt::config::server'),
    }
  }

  cron { 'letsencrypt-renew-reload':
    ensure  => present,
    command => '/opt/letsencrypt/letsencrypt-auto renew --quiet --renew-hook="service apache2 reload"',
    hour    => 12,
    user    => 'root',
  }
}
