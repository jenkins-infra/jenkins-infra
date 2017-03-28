require 'spec_helper'

describe 'profile::kubernetes::resources::nginx' do

   it { should contain_class('profile::kubernetes::params') }
   it { should contain_class('profile::kubernetes::kubectl') }
   it { should contain_file("/home/k8s/resources/nginx").with(
     :ensure => 'directory',
     :owner  => 'k8s'
     )
   }

   it { should contain_profile__kubernetes__apply('nginx/namespace.yaml')}
   it { should contain_profile__kubernetes__apply('nginx/configmap.yaml')}
   it { should contain_profile__kubernetes__apply('nginx/default-deployment.yaml')}
   it { should contain_profile__kubernetes__apply('nginx/deployment.yaml')}
   it { should contain_profile__kubernetes__apply('nginx/default-service.yaml')}
   it { should contain_profile__kubernetes__apply('nginx/service.yaml')}
   it { should contain_exec('Reload nginx-ingress pods')}
end
