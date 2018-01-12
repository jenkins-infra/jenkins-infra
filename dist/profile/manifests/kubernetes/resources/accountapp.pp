#   Class: profile::kubernetes::resources::accountapp
#
#   This class deploys the Jenkins account-app to Kubernetes
#
#   Parameters:
#     $clusters:
#       clusters contains a list of cluster information.
#     $domain_name:
#       account app url endpoint
#     $domain_alias:
#       account app alias endpoint
#     $election_candidates:
#       coma separated list of candidates.
#     $election_close:
#       date election will close. yyyy/MM/dd
#     $election_open:
#       date app will start collecting votes. yyyy/MM/dd
#     $election_logdir:
#       collected votes directory.
#     $image_tag:
#       Set accountapp image tag.
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
#     $seats:
#       Define number of elected seats for current election
#     $seniority:
#       Define seniority in month required to vote
#     $smtp_server:
#       smtp server
#     $smtp_user:
#       smtp user
#     $smtp_password:
#       smtp password
#     $smtp_auth:
#       smtp authentication (boolean)
#
#   Remark:
#     `kubectl get service nginx --namespace nginx-ingress` return service public ip
#     This public ip should be used for DNS record frontend_url -> this IP
#     In order to create letsencrypt certificates
#
# Deploy accountapp resources on kubernetes cluster
class profile::kubernetes::resources::accountapp (
    Array $clusters = $profile::kubernetes::params::clusters,
    Array $domain_alias = ['accounts.jenkins-ci.org'],
    String $domain_name = 'accounts.jenkins.io',
    String $election_close = '1970-01-02',
    String $election_open = '1970-01-01',
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
    String $seats = '2',
    String $seniority = '12',
    String $smtp_server = 'localhost',
    String $smtp_user = '',
    String $smtp_password = '',
    String $storage_account_name = '',
    String $storage_account_key = '',
    Boolean $smtp_auth = true
  ) inherits profile::kubernetes::params {

  require profile::kubernetes::kubectl
  require profile::kubernetes::resources::nginx
  require profile::kubernetes::resources::lego

  $clusters.each | $cluster | {
    $context = $cluster['clustername']

    file { "${profile::kubernetes::params::resources}/${context}/accountapp":
      ensure => 'directory',
      owner  => $profile::kubernetes::params::user,
    }

    profile::kubernetes::apply { "accountapp/service.yaml on ${context}":
      context  => $context,
      resource => 'accountapp/service.yaml'
    }

    profile::kubernetes::apply { "accountapp/secret.yaml on ${context}":
      context    => $context,
      parameters => {
        'jira_password'        => base64('encode', $jira_password, 'strict'),
        'ldap_password'        => base64('encode', $ldap_password, 'strict'),
        'smtp_password'        => base64('encode', $smtp_password, 'strict'),
        'storage_account_name' => base64('encode', $storage_account_name, 'strict'),
        'storage_account_key'  => base64('encode', $storage_account_key, 'strict')
      },
      resource   => 'accountapp/secret.yaml'
    }

    profile::kubernetes::apply { "accountapp/ingress-tls.yaml on ${context}":
      context    => $context,
      parameters => {
        'url'     => $domain_name,
        'aliases' => $domain_alias
      },
      resource   =>  'accountapp/ingress-tls.yaml'
    }

    profile::kubernetes::apply { "accountapp/deployment.yaml on ${context}":
      context    => $context,
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
        'seats'                 => $seats,
        'seniority'             => $seniority,
        'smtp_server'           => $smtp_server,
        'smtp_user'             => $smtp_user,
        'smtp_auth'             => $smtp_auth,
        'url'                   => "https://${domain_name}/"
      },
      resource   => 'accountapp/deployment.yaml'
    }

    profile::kubernetes::reload { "accountapp pods on ${context}":
      app        => 'accountapp',
      context    => $context,
      depends_on => [
        'accountapp/secret.yaml'
      ]
    }

    profile::kubernetes::backup { "accountapp-tls on ${context}":
      context =>  $context
    }
  }
}
