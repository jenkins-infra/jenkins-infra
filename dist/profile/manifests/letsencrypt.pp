#
# This profile configures letsencrypt on the host it's applied to
class profile::letsencrypt {
  class { '::letsencrypt':
    config => {
        email  => hiera('letsencrypt::config::email'),
        server => hiera('letsencrypt::config::server'),
    }
  }

}
