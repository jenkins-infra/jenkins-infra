require 'spec_helper'

describe 'profile::kubernetes::resources::registry' do
   let (:params) do
       {
          :dockerconfigjson  => 'dockerconfigjsonsecret',
       }
   end
   it { should contain_class('profile::kubernetes::params') }
   it { should contain_class('profile::kubernetes::kubectl') }

   it { should contain_file("/home/k8s/resources/registry").with(
     :ensure => 'directory',
     :owner  => 'k8s'
     )
   }
   it { should contain_profile__kubernetes__apply('registry/secret.yaml').with(
     :parameters => {
        'dockerconfigjson' => 'dockerconfigjsonsecret',
        }
     )
   }
end
