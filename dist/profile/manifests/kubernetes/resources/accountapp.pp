#   Class: profile::kubernetes::resources::accountapp
#
#   This class deploy plugins jenkins website
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
#     $election_logfile:
#       path to store collected votes.
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
#     $url:
#       account app url endpoint
#
#   Remark:
#     `kubectl get service nginx --namespace nginx-ingress` return service public ip
#     This public ip should be used for DNS record frontend_url -> this IP
#     In order to create letsencrypt certificates
#
# Deploy accountapp resources on kubernetes cluster
class profile::kubernetes::resources::accountapp (
    String $election_close = '2038/01/19',
    String $election_open = '1970/01/01',
    String $election_logfile = '/var/log/accountapp/elections.log',
    String $election_candidates = 'bob,alice',
    String $image_tag = 'latest',
    String $jira_username = 'jira_username',
    String $jira_url = 'https://jira_url',
    String $jira_password = 'jira_password',
    String $ldap_manager_dn = 'cn=admin,dc=jenkins-ci,dc=org',
    String $ldap_new_user_base_dn = '',
    String $ldap_password = 'ldap_password',
    String $ldap_url = 'ldap://localhost:389/',
    String $recaptcha_private_key = 'recaptcha_private_key',
    String $recaptcha_public_key = 'recaptcha_public_key',
    String $smtp_server = 'localhost',
    String $url = 'accounts.jenkins.io'
  ){
  include profile::kubernetes::params
  require profile::kubernetes::kubectl
  require profile::kubernetes::resources::nginx
  require profile::kubernetes::resources::lego

  file { "${profile::kubernetes::params::resources}/accountapp":
    ensure => 'directory',
    owner  => $profile::kubernetes::params::user,
  }

  profile::kubernetes::apply { 'accountapp/ingress-tls.yaml':
    parameters  => {
      'url'     => $url,
    }
  }
  profile::kubernetes::apply { 'accountapp/service.yaml':}

  profile::kubernetes::apply { 'accountapp/secret.yaml':
    parameters  => {
      'ldap_password'         => base64('encode', $ldap_password, 'strict'),
      'jira_password'         => base64('encode', $jira_password, 'strict'),
      'recaptcha_private_key' => base64('encode', $recaptcha_private_key, 'strict')
    }
  }

  profile::kubernetes::apply { 'accountapp/deployment.yaml':
    parameters => {

      'election_close'        => $election_close,
      'election_open'         => $election_open,
      'election_logfile'      => $election_logfile,
      'election_candidates'   => $election_candidates,
      'url'                   => "https://${url}",
      'ldap_url'              => $ldap_url,
      'ldap_manager_dn'       => $ldap_manager_dn,
      'ldap_new_user_base_dn' => $ldap_new_user_base_dn,
      'jira_username'         => $jira_username,
      'jira_url'              => $jira_url,
      'recaptcha_public_key'  => $recaptcha_public_key,
      'smtp_server'           => $smtp_server,
      'image_tag'             => $image_tag
    }
  }


  # As configmap changes do not trigger pods update,
  # we must reload pods 'manually' to use the newly updated configmap
  exec { 'Reload accountapp pods':
    path        => ["${profile::kubernetes::params::bin}/"],
    command     => 'kubectl delete pods -l app=accountapp',
    refreshonly => true,
    environment => ["KUBECONFIG=${profile::kubernetes::params::home}/.kube/config"] ,
    logoutput   => true,
    subscribe   => Exec['apply accountapp/secret.yaml']
  }
}
