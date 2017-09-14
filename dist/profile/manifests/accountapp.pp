#
# Profile cleaning the necessary resources to provision our LDAP-based
# accountapp
# Remark, following resources are not removed:
#   - docker image: jenkinsciinfra/account-app
#   - service file: /etc/init.d/docker-account-app
#
class profile::accountapp(
  $image_tag = '23-build5a2c1e',
) {
  include profile::docker
  include profile::apachemisc

  validate_string($image_tag)

  $vhosts = [
    'accounts.jenkins.io',
    'accounts.jenkins.io unsecured'
    ]

  $files = [
    '/etc/accountapp',
    '/etc/letsencrypt/live/accounts.jenkins.io/privkey.pem',
    '/etc/letsencrypt/live/accounts.jenkins.io/cert.pem',
    '/etc/letsencrypt/live/accounts.jenkins.io/chain.pem',
    ]

  # Remark this only delete docker container but do not remove the init.d service
  docker::run { 'account-app':
    ensure => 'absent',
    image  => "jenkinsciinfra/account-app:${image_tag}",
  }

  $vhosts.each | String $vhost| {
    apache::vhost { $vhost:
      ensure  => 'absent',
      docroot => '/var/www/html/',
    }
  }

  $files.each | String $file| {
    file { $file:
      ensure => 'absent',
      force  => true
    }
  }
}
