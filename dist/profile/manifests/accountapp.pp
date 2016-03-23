#
# Profile defining the necessary resources to provision our LDAP-based
# accountapp
class profile::accountapp(
  # all injected from hiera
  $image_tag,
  $ldap_url = 'ldap://localhost:389/',
  $ldap_password = '',
  $smtp_server = 'localhost',
  $recaptcha_key = '',
  $app_url = 'https://accounts.jenkins.io/',
) {
  include ::firewall
  include profile::docker
  include profile::apache-misc

  class { 'letsencrypt':
    config => {
        email  => hiera('letsencrypt::config::email'),
        server => hiera('letsencrypt::config::server'),
    }
  }

  validate_string($image_tag)
  validate_string($ldap_url)
  validate_string($ldap_password)
  validate_string($smtp_server)
  validate_string($recaptcha_key)

  file { '/etc/accountapp' :
    ensure => directory,
    # Don't allow anything not declared in Puppet to be dropped in there
    purge  => true,
  }

  file { '/etc/accountapp/config.properties':
    ensure  => file,
    content => template("${module_name}/accountapp/config.properties.erb"),
    require => File['/etc/accountapp'],
  }

  docker::image { 'jenkinsciinfra/account-app':
    image_tag => $image_tag,
  }

  docker::run { 'account-app':
    command          => undef,
    image            => "jenkinsciinfra/account-app:${image_tag}",
    volumes          => ['/etc/accountapp:/etc/accountapp'],
    require          => File['/etc/accountapp/config.properties'],
    extra_parameters => ['--net=host'],
  }

  # docroot is required for apache::vhost but should never be used because
  # we're proxying everything here
  $docroot = '/var/www/html'

  apache::vhost { 'accounts.jenkins.io':
    serveraliases => [
      'accounts.jenkins-ci.org',
    ],
    port          => '443',
    ssl           => true,
    docroot       => $docroot,
    proxy_pass    => [
      {
        path         => '/',
        url          => 'http://localhost:8080/',
        reverse_urls => 'http://localhost:8080/',
      },
    ],
  }

  apache::vhost { 'accounts.jenkins.io unsecured':
    servername      => 'accounts.jenkins.io',
    serveraliases   => [
      'accounts.jenkins-ci.org',
    ],
    port            => '80',
    docroot         => $docroot,
    redirect_status => 'permanent',
    redirect_dest   => $app_url,
  }

  letsencrypt::certonly { 'accounts.jenkins.io':
    domains     => ['accounts.jenkins.io', 'accounts.jenkins-ci.org'],
    plugin      => 'apache',
    manage_cron => true,
  }
}
