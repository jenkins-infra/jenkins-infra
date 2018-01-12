require 'spec_helper'

describe 'profile::kubernetes::resources::registry' do
  it { should contain_class('profile::kubernetes::params') }
  it { should contain_class('profile::kubernetes::kubectl') }

  it {
    should contain_file('/home/k8s/resources/minikube/registry').with(
      'ensure' => 'directory',
      'owner'  => 'k8s'
    )
  }
  it {
    should contain_profile__kubernetes__apply('registry/secret.yaml on minikube')
      .with(
        'parameters' => {
          'dockerconfigjson' => 'eyJhdXRocyI6IHsiaHR0cHM6Ly9pbmRleC5kb2NrZXIuaW8vdjEvIjogeyJhdXRoIjogImJhc2U2NF9hdXRoIn19fQ==',
        }
      )
  }
end
