require 'spec_helper'

describe 'profile::kubernetes::resources::datadog' do
   let (:params) do 
       {
          :apiKey    => 'datadogapikey',
       }
   end
   it { should contain_class('profile::kubernetes::params') }
   it { should contain_class('profile::kubernetes::kubectl') }
   it { should contain_file("/home/k8s/resources/datadog").with(
     :ensure => 'directory',
     :owner  => 'k8s'
     )
   }
   it { should contain_profile__kubernetes__apply('datadog/daemonset.yaml')}
   it { should contain_profile__kubernetes__apply('datadog/deployment.yaml')}
   it { should contain_profile__kubernetes__apply('datadog/secret.yaml').with(
     :parameters => { 'apiKey' => 'datadogapikey'}
     )
   }
   it { should contain_exec('Reload datadog pods')}
end
