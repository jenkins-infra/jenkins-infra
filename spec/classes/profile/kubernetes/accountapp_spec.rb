require 'spec_helper'

describe 'profile::kubernetes::resources::accountapp' do
   let (:params) do 
       {
           :election_close        => '2038/01/19',
           :election_open         => '1970/01/01',
           :election_logfile      => '/var/log/accountapp/elections.log',
           :election_candidates   => 'bob,alice',
           :url                   => 'accounts.jenkins.test',
           :image_tag             => 'latest',
           :ldap_url              => 'https://ldap.jenkins-ci.test',
           :ldap_password         => 'ldap_password',
           :ldap_manager_dn       => 'cn=admin,dc=jenkins-ci,dc=org',
           :ldap_new_user_base_dn => '',
           :jira_username         => 'accountapp',
           :jira_url              => 'https://issues.jenkins-ci.test',
           :jira_password         => 'jira_password',
           :recaptcha_public_key  => 'recaptcha_public_key',
           :recaptcha_private_key => 'recaptcha_private_key',
           :smtp_server           => 'smtp_server'

       }
   end
   it { should contain_class('profile::kubernetes::params') }
   it { should contain_class('profile::kubernetes::kubectl') }
   it { should contain_class('profile::kubernetes::resources::nginx') }
   it { should contain_class('profile::kubernetes::resources::lego') }

   it { should contain_file("/home/k8s/resources/accountapp").with(
     :ensure => 'directory',
     :owner  => 'k8s'
     )
   }
   it { should contain_profile__kubernetes__apply('accountapp/ingress-tls.yaml')}
   it { should contain_profile__kubernetes__apply('accountapp/service.yaml')}
   it { should contain_profile__kubernetes__apply('accountapp/secret.yaml').with(
     :parameters => { 
        'ldap_password' 		=> 'bGRhcF9wYXNzd29yZA==',
        'jira_password'         => 'amlyYV9wYXNzd29yZA==',
        'recaptcha_private_key' => 'cmVjYXB0Y2hhX3ByaXZhdGVfa2V5'
        }
     )
   }
   it { should contain_profile__kubernetes__apply('accountapp/deployment.yaml').with(
	 :parameters => {
       'election_close'        => '2038/01/19',
       'election_open'         => '1970/01/01',
       'election_logfile'      => '/var/log/accountapp/elections.log',
       'election_candidates'   => 'bob,alice',
       'url'                   => 'https://accounts.jenkins.test',
       'ldap_url'              => 'https://ldap.jenkins-ci.test',
       'ldap_manager_dn'       => 'cn=admin,dc=jenkins-ci,dc=org',
       'ldap_new_user_base_dn' => '',
       'jira_username'         => 'accountapp',
       'jira_url'              => 'https://issues.jenkins-ci.test',
       'recaptcha_public_key'  => 'recaptcha_public_key',
       'smtp_server'           => 'smtp_server',
       'image_tag'             => 'latest'
	   }
	 )
   }
   it { should contain_exec('Reload accountapp pods')}
end
