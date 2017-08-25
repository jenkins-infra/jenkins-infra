require 'spec_helper'

describe 'profile::kubernetes::resources::registry' do
   let (:params) do
       {
          :dockerconfigjson  => '{"registry.azurecr.io":{"auth":"fake_auth"}}',
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
        'dockerconfigjson' => 'eyJyZWdpc3RyeS5henVyZWNyLmlvIjp7ImF1dGgiOiJmYWtlX2F1dGgifX0=',
        }
     )
   }
end
