require 'spec_helper'

describe 'profile::kubernetes::resources::accountapp' do
  let(:params) do
    {
      'election_close'        => '2038-01-19',
      'election_open'         => '1970-01-01',
      'election_logdir'       => '/var/log/accountapp/elections',
      'election_candidates'   => 'bob,alice',
      'domain_name'           => 'accounts.jenkins.test',
      'image_tag'             => 'latest',
      'ldap_url'              => 'ldap://ldap.jenkins-ci.test',
      'ldap_password'         => 'ldap_password',
      'ldap_manager_dn'       => 'cn=admin,dc=jenkins-ci,dc=org',
      'ldap_new_user_base_dn' => 'ou=people,dc=jenkins-ci,dc=org',
      'jira_username'         => 'accountapp',
      'jira_url'              => 'https://issues.jenkins-ci.test',
      'jira_password'         => 'jira_password',
      'seats'                 => '2',
      'seniority'             => '12',
      'smtp_server'           => 'smtp.jenkins.test',
      'smtp_auth'             => true,
      'smtp_password'         => 'smtp_password',
      'smtp_user'             => 'smtp_user',
      'storage_account_name'  => 'infratestaccountapp_name',
      'storage_account_key'   => 'infratestaccountapp_key'
    }
  end

  it { should contain_class('profile::kubernetes::kubectl') }
  it { should contain_class('profile::kubernetes::resources::nginx') }
  it { should contain_class('profile::kubernetes::resources::lego') }

  it {
    should contain_file('/home/k8s/resources/minikube/accountapp').with(
      'ensure' => 'directory',
      'owner' => 'k8s'
    )
  }
  it {
    should contain_profile__kubernetes__apply('accountapp/ingress-tls.yaml on minikube')
  }

  it {
    should contain_profile__kubernetes__apply('accountapp/service.yaml on minikube')
  }

  it {
    should contain_profile__kubernetes__apply('accountapp/secret.yaml on minikube')
      .with(
        'context'    => 'minikube',
        'parameters' => {
          'ldap_password'         => 'bGRhcF9wYXNzd29yZA==',
          'jira_password'         => 'amlyYV9wYXNzd29yZA==',
          'smtp_password'         => 'c210cF9wYXNzd29yZA==',
          'storage_account_name'  => 'aW5mcmF0ZXN0YWNjb3VudGFwcF9uYW1l',
          'storage_account_key'   => 'aW5mcmF0ZXN0YWNjb3VudGFwcF9rZXk='
        }
      )
  }
  it {
    should contain_profile__kubernetes__apply('accountapp/deployment.yaml on minikube')
      .with(
        'context'    => 'minikube',
        'parameters' => {
          'election_close'        => '2038-01-19',
          'election_open'         => '1970-01-01',
          'election_logdir'       => '/var/log/accountapp/elections',
          'election_candidates'   => 'bob,alice',
          'image_tag'             => 'latest',
          'jira_username'         => 'accountapp',
          'jira_url'              => 'https://issues.jenkins-ci.test',
          'ldap_url'              => 'ldap://ldap.jenkins-ci.test',
          'ldap_manager_dn'       => 'cn=admin,dc=jenkins-ci,dc=org',
          'ldap_new_user_base_dn' => 'ou=people,dc=jenkins-ci,dc=org',
          'seats'                 => '2',
          'seniority'             => '12',
          'smtp_server'           => 'smtp.jenkins.test',
          'smtp_user'             => 'smtp_user',
          'smtp_auth'             => true,
          'url'                   => 'https://accounts.jenkins.test/'
        }
      )
  }
  it { should contain_profile__kubernetes__reload('accountapp pods on minikube') }
end
