#   Class: profile::kubernetes::resources::accountapp
#
#   This class deploys the Jenkins account-app to Kubernetes
#
#   Parameters:
#     $image_tag:
#       Set accountapp image tag.
#     $election_candidates:
#       coma separated list of candidates.
#     $election_close:
#       date election will close. yyyy/MM/dd
#     $election_open:
#       date app will start collecting votes. yyyy/MM/dd
#     $election_logdir:
#       collected votes directory.
#     $jira_username:
#       jira username
#     $jira_url:
#       jira url endpoint
#     $jira_password:
#       jira password
#     $ldap_manager_dn:
#       ldap manager dn
#     $ldap_new_user_base_dn:
#       ldap new user base dn
#     $ldap_password:
#       ldap password
#     $ldap_url:
#       ldap endpoint
#     $recaptcha_private_key:
#       recaptcha private key
#     $recaptcha_public_key:
#       recaptcha public key
#     $smtp_server:
#       smtp server
#     $smtp_user:
#       smtp user
#     $smtp_password:
#       smtp password
#     $smtp_auth:
#       smtp authentication (boolean)
#     $domain_name:
#       account app url endpoint
#     $domain_alias:
#       account app alias endpoint
#
#   Remark:
#     `kubectl get service nginx --namespace nginx-ingress` return service public ip
#     This public ip should be used for DNS record frontend_url -> this IP
#     In order to create letsencrypt certificates
#
# Deploy accountapp resources on kubernetes cluster
class profile::kubernetes::resources::accountapp (
    String $election_close = '1970/01/02',
    String $election_open = '1970/01/01',
    String $election_logdir= '/var/log/accountapp/elections',
    String $election_candidates = 'bob,alice',
    String $image_tag = 'latest',
    String $jira_username = 'jira_username',
    String $jira_url = 'https://jira_url',
    String $jira_password = 'jira_password',
    String $ldap_manager_dn = 'cn=admin,dc=jenkins-ci,dc=org',
    String $ldap_new_user_base_dn = 'ou=people,dc=jenkins-ci,dc=org',
    String $ldap_password = 'ldap_password',
    String $ldap_url = 'ldap://localhost:389/',
    String $recaptcha_private_key = 'recaptcha_private_key',
    String $recaptcha_public_key = 'recaptcha_public_key',
    String $smtp_server = 'localhost',
    String $smtp_user = '',
    String $smtp_password = '',
    Boolean $smtp_auth = true,
    String $storage_account_name = '',
    String $storage_account_key = '',
    String $domain_name = 'accounts.jenkins.io',
    Array $domain_alias = ['accounts.jenkins-ci.org']
  ){
  include profile::kubernetes::params
  require profile::kubernetes::kubectl
  require profile::kubernetes::resources::nginx
  require profile::kubernetes::resources::lego

  file { "${profile::kubernetes::params::resources}/accountapp":
    ensure => 'directory',
    owner  => $profile::kubernetes::params::user,
  }

  profile::kubernetes::apply { 'accountapp/service.yaml':}

  profile::kubernetes::apply { 'accountapp/secret.yaml':
    parameters  => {
      'jira_password'         => base64('encode', $jira_password, 'strict'),
      'ldap_password'         => base64('encode', $ldap_password, 'strict'),
      'smtp_password'         => base64('encode', $smtp_password, 'strict'),
      'recaptcha_private_key' => base64('encode', $recaptcha_private_key, 'strict'),
      'storage_account_name'  => base64('encode', $storage_account_name, 'strict'),
      'storage_account_key'   => base64('encode', $storage_account_key, 'strict')
    }
  }

  profile::kubernetes::apply { 'accountapp/ingress-tls.yaml':
    parameters  => {
      'url'     => $domain_name,
      'aliases' => $domain_alias
    }
  }

  profile::kubernetes::apply { 'accountapp/deployment.yaml':
    parameters => {
      'election_close'        => $election_close,
      'election_open'         => $election_open,
      'election_logdir'       => $election_logdir,
      'election_candidates'   => $election_candidates,
      'image_tag'             => $image_tag,
      'jira_username'         => $jira_username,
      'jira_url'              => $jira_url,
      'ldap_url'              => $ldap_url,
      'ldap_manager_dn'       => $ldap_manager_dn,
      'ldap_new_user_base_dn' => $ldap_new_user_base_dn,
      'recaptcha_public_key'  => $recaptcha_public_key,
      'smtp_server'           => $smtp_server,
      'smtp_user'             => $smtp_user,
      'smtp_auth'             => $smtp_auth,
      'url'                   => "https://${domain_name}/"
    }
  }

  profile::kubernetes::reload { 'accountapp pods':
    app        => 'accountapp',
    depends_on => [
      'accountapp/secret.yaml'
    ]
  }

  profile::kubernetes::backup { 'accountapp-tls':
  }
}
