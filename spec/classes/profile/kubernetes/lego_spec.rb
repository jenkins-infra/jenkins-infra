require 'spec_helper'

describe 'profile::kubernetes::resources::lego' do
   let (:params) do
       {
          :email  => 'infra@lists.jenkins-ci.org',
          :url    => 'https://acme-v01.api.letsencrypt.org/directory'
       }
   end
   it { should contain_class('profile::kubernetes::params') }
   it { should contain_class('profile::kubernetes::kubectl') }
   it { should contain_file("/home/k8s/resources/lego").with(
     :ensure => 'directory',
     :owner  => 'k8s'
     )
   }
   it { should contain_profile__kubernetes__apply('lego/deployment.yaml')}
   it { should contain_profile__kubernetes__apply('lego/namespace.yaml')}
   it { should contain_profile__kubernetes__apply('lego/configmap.yaml').with(
     :parameters => {
        'email' => 'infra@lists.jenkins-ci.org',
        'url'   => 'https://acme-v01.api.letsencrypt.org/directory'
        }
     )
   }
   it { should contain_exec('Reload lego pods')}
end
