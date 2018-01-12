require 'spec_helper'

describe 'profile::kubernetes::resources::kube_state_metrics' do

  it { should contain_class('profile::kubernetes::kubectl') }

  it {
    should contain_file('/home/k8s/resources/minikube/kube_state_metrics')
      .with(
        'ensure' => 'directory',
        'owner'  => 'k8s'
      )
  }

  it { should contain_profile__kubernetes__apply('kube_state_metrics/service.yaml on minikube') }

  it {
    should contain_profile__kubernetes__apply('kube_state_metrics/deployment.yaml on minikube')
      .with(
        'parameters' => {
          'image_tag' => 'v0.4.1'
        }
      )
  }
end
