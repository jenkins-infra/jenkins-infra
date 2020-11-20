#
# This profile configures letsencrypt on the host it's applied to
class profile::letsencrypt {
  class { '::letsencrypt':
    config => {
        email  => lookup('letsencrypt::config::email'),
        server => lookup('letsencrypt::config::server'),
    }
  }

  package { 'python-certbot-apache':
    ensure => present
  }
}
