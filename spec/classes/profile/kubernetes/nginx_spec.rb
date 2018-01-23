require 'spec_helper'

describe 'profile::kubernetes::resources::nginx' do

  let(:facts) do
    {
      path: '/usr/bin'
    }
  end

  it { should contain_class('profile::kubernetes::kubectl') }

  it {
    should contain_file('/home/k8s/resources/minikube/nginx')
      .with(
        ensure: 'directory',
        owner: 'k8s'
      )
  }

  it {
    should contain_profile__kubernetes__apply('nginx/namespace.yaml on minikube')
  }

  it {
    should contain_profile__kubernetes__apply('nginx/configmap.yaml on minikube')
  }

  it {
    should contain_profile__kubernetes__apply('nginx/default-deployment.yaml on minikube')
  }

  it {
    should contain_profile__kubernetes__apply('nginx/daemonset.yaml on minikube')
  }

  it {
    should contain_profile__kubernetes__apply('nginx/default-service.yaml on minikube')
  }

  it {
    should contain_profile__kubernetes__apply('nginx/service.yaml on minikube')
  }

  it {
    should contain_profile__kubernetes__reload('nginx pods on minikube')
  }
  it {
    should contain_profile__kubernetes__delete('nginx/deployment.yaml on minikube')
  }
end
