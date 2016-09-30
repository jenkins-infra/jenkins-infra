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
  $jira_url = 'https://issues.jenkins-ci.org/',
  $jira_username = accountapp,
  $jira_password = '',
) {
  include ::firewall
  include profile::docker
  include profile::letsencrypt
  include profile::apachemisc

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
    env              => [
      "LDAP_URL=${ldap_url}",
      "LDAP_PASSWORD=${ldap_password}",
      "JIRA_URL=${jira_url}",
      "JIRA_USERNAME=${jira_username}",
      "JIRA_PASSWORD=${jira_password}",
    ],
    extra_parameters => ['--net=host'],
  }

  profile::datadog_check { 'accountapp-http-check':
    checker => 'http_check',
    source  => 'puppet:///modules/profile/accountapp/http_check.yaml',
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

  # We can only acquire certs in production due to the way the letsencrypt
  # challenge process works
  if (($::environment == 'production') and ($::vagrant != '1')) {
    letsencrypt::certonly { 'accounts.jenkins.io':
        domains     => ['accounts.jenkins.io', 'accounts.jenkins-ci.org'],
        plugin      => 'apache',
        manage_cron => true,
    }

    Apache::Vhost <| title == 'accounts.jenkins.io' |> {
      ssl_key       => '/etc/letsencrypt/live/accounts.jenkins.io/privkey.pem',
      # When Apache is upgraded to >= 2.4.8 this should be changed to
      # fullchain.pem
      ssl_cert      => '/etc/letsencrypt/live/accounts.jenkins.io/cert.pem',
      ssl_chain     => '/etc/letsencrypt/live/accounts.jenkins.io/chain.pem',
    }
  }
}
