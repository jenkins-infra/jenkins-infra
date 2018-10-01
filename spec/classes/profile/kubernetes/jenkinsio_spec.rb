require 'spec_helper'

describe 'profile::kubernetes::resources::jenkinsio' do
  let(:params) do
    {
      'storage_account_key' => 'storage_account_key',
      'storage_account_name' => 'storage_account_name',
      'image_tag' => 'alpine'
    }
  end

  it { should contain_class('stdlib') }
  it { should contain_class('profile::kubernetes::params') }
  it { should contain_class('profile::kubernetes::kubectl') }

  it {
    should contain_file('/home/k8s/resources/minikube/jenkinsio')
      .with(
        'ensure' => 'directory',
        'owner'  => 'k8s'
      )
  }

  it { should contain_profile__kubernetes__apply('jenkinsio/service.yaml on minikube')}
  it { should contain_profile__kubernetes__apply('jenkinsio/cn-service.yaml on minikube')}
  it { should contain_profile__kubernetes__apply('jenkinsio/cn-endpoint.yaml on minikube')}

  it {
    should contain_profile__kubernetes__apply('jenkinsio/deployment.yaml on minikube')
      .with(
        'context'    => 'minikube',
        'parameters' => {
          'image_tag' => 'alpine'
        }
      )
  }

  it {
    should contain_profile__kubernetes__apply('jenkinsio/secret.yaml on minikube')
      .with(
        'context'    => 'minikube',
        'parameters' => {
          'storage_account_name' => 'c3RvcmFnZV9hY2NvdW50X25hbWU=',
          'storage_account_key' => 'c3RvcmFnZV9hY2NvdW50X2tleQ=='
        }
      )
  }

  it {
    should contain_profile__kubernetes__apply('jenkinsio/ingress-tls.yaml on minikube')
      .with(
        'context'    => 'minikube',
        'parameters' => {
          'url'     => 'www.jenkins.io',
          'aliases' => [
            'jenkins.io',
            'jenkins-ci.org',
            'www.jenkins-ci.org'
          ]

        }
      )
  }
  it { should contain_profile__kubernetes__reload('jenkinsio pods on minikube') }
end
