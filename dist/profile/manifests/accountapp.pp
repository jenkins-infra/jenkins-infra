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
  String $election_close = '1970-01-02',
  String $election_open = '1970-01-01',
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
  String $seats = '2',
  String $seniority = '12',
  String $smtp_server = 'localhost',
  String $smtp_user = '',
  String $smtp_password = '',
  Boolean $smtp_auth = true,

) {
  include profile::docker
  include profile::apachemisc
  include profile::letsencrypt

  $docroot = '/var/www/html'

  # Used by accountapp to write vote results.
  # Because the docker image run as user jetty, whose not present on the docker node,
  # I put a very bad permission on /var/log/accountapp in order to avoid permission issue.
  #
  file { '/var/log/accountapp':
    ensure => 'absent',
  }

  docker::run { 'accountapp':
    ensure => 'absent',
    image  => "jenkinsciinfra/account-app:${image_tag}",
  }

  # docroot is required for apache::vhost but should never be used because
  # we're proxying everything here

  apache::vhost { $domain_name :
    ensure  => 'absent',
    docroot => $docroot,
  }

  apache::vhost { "${domain_name} unsecured":
    ensure  => 'absent',
    docroot => $docroot,
  }
}
