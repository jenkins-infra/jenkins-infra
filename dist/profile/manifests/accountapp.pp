#
# Profile cleaning the necessary resources to provision our LDAP-based
# accountapp
# Remark, following resources are not removed:
#   - docker image: jenkinsciinfra/account-app
#   - service file: /etc/init.d/docker-account-app
#
class profile::accountapp(
  String $domain_name = 'accounts.jenkins.io',
  String $domain_alias = 'accounts.jenkins-ci.org',
  String $election_close = '1970/01/02',
  String $election_open = '1970/01/01',
  String $election_logdir= '/var/log/accountapp/elections',
  String $election_candidates = 'bob,alice',
  String $image_tag = '52-buildce5349',
  String $jira_url = 'https://issues.jenkins-ci.org/',
  String $jira_username = accountapp,
  String $jira_password = '',
  String $ldap_manager_dn = '',
  String $ldap_new_user_base_dn = '',
  String $ldap_url = 'ldap://localhost:389/',
  String $ldap_password = '',
  String $recaptcha_private_key = '',
  String $recaptcha_public_key = '',
  String $smtp_server = 'localhost',
  String $smtp_user = '',
  String $smtp_password = '',
  Boolean $smtp_auth = true,

) {
  include profile::docker
  include profile::apachemisc

  $docroot = '/var/www/html'

  # Used by accountapp to write vote results.
  # Because the docker image run as user jetty, whose not present on the docker node,
  # I put a very bad permission on /var/log/accountapp in order to avoid permission issue.
  #
  file { '/var/log/accountapp':
    ensure => 'directory',
    mode   => '0777',
    group  => 'docker'
  }

  docker::run { 'accountapp':
    ensure => 'present',
    ports   => ['8080:8080'],
    volumes => ['/var/log/accountapp/:/var/log/accountapp'],
    image  => "jenkinsciinfra/account-app:${image_tag}",
    env    => [
      "ELECTION_CLOSE='${election_close}'",
      "ELECTION_OPEN='${election_open}'",
      "ELECTION_LOGDIR='${election_logdir}'",
      "ELECTION_CANDIDATES='${election_candidates}'",
      "JIRA_PASSWORD='${jira_password}'",
      "JIRA_USERNAME='${jira_username}'",
      "JIRA_URL='${jira_url}'",
      "LDAP_URL='${ldap_url}'",
      "LDAP_MANAGER_DN='${ldap_manager_dn}'",
      "LDAP_NEW_USER_BASE_DN='${ldap_new_user_base_dn}'",
      "LDAP_PASSWORD='${ldap_password}'",
      "RECAPTCHA_PRIVATE_KEY='${recaptcha_private_key}'",
      "RECAPTCHA_PUBLIC_KEY='${recaptcha_public_key}'",
      "SMTP_PASSWORD='${smtp_password}'",
      "SMTP_SERVER='${smtp_server}'",
      "SMTP_USER='${smtp_user}'",
      "SMTP_AUTH='${smtp_auth}'",
      "URL='https://${domain_name}/'"
    ]
  }

  # docroot is required for apache::vhost but should never be used because
  # we're proxying everything here

  apache::vhost { $domain_name :
    serveraliases => [
      $domain_alias
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

  apache::vhost { "${domain_name} unsecured":
    servername      => $domain_name,
    serveraliases   => [
      $domain_alias,
    ],
    port            => '80',
    docroot         => $docroot,
    redirect_status => 'permanent',
    redirect_dest   => "https://${domain_name}",
  }

  # We can only acquire certs in production due to the way the letsencrypt
  # challenge process works
  if (($::environment == 'production') and ($::vagrant != '1')) {
    letsencrypt::certonly { $domain_name:
        domains     => [ $domain_name , $domain_alias],
        plugin      => 'apache',
        manage_cron => true,
    }
    Apache::Vhost <| title == $domain_name |> {
      ssl_key   => "/etc/letsencrypt/live/${domain_name}/privkey.pem",
      # When Apache is upgraded to >= 2.4.8 this should be changed to
      # fullchain.pem
      ssl_cert  => "/etc/letsencrypt/live/${domain_name}/cert.pem",
      ssl_chain => "/etc/letsencrypt/live/${domain_name}/chain.pem",
    }
  }
###


}
