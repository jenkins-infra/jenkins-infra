require 'spec_helper'

describe 'profile::kubernetes::resources::lego' do
  let(:params) do
    {
      'email'  => 'infra@lists.jenkins-ci.org',
      'url'    => 'https://acme-v01.api.letsencrypt.org/directory'
    }
  end

  it { should contain_class('profile::kubernetes::params') }
  it { should contain_class('profile::kubernetes::kubectl') }

  it {
    should contain_file('/home/k8s/resources/minikube/lego')
      .with(
        'ensure' => 'directory',
        'owner'  => 'k8s'
      )
  }
  it {
    should contain_profile__kubernetes__apply('lego/deployment.yaml on minikube')
  }

  it {
    should contain_profile__kubernetes__apply('lego/namespace.yaml on minikube')
  }

  it {
    should contain_profile__kubernetes__apply('lego/configmap.yaml on minikube')
      .with(
        'parameters' => {
          'email' => 'infra@lists.jenkins-ci.org',
          'url'   => 'https://acme-v01.api.letsencrypt.org/directory'
        }
      )
  }
  it { should contain_profile__kubernetes__reload('kube-lego pods on minikube') }
end
