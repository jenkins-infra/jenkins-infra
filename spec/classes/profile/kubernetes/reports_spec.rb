require 'spec_helper'

describe 'profile::kubernetes::resources::reports' do
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
    should contain_file('/home/k8s/resources/minikube/reports')
      .with(
        'ensure' => 'directory',
        'owner'  => 'k8s'
      )
  }

  it { should contain_profile__kubernetes__apply('reports/service.yaml on minikube')}

  it {
    should contain_profile__kubernetes__apply('reports/deployment.yaml on minikube')
      .with(
        'context'    => 'minikube',
        'parameters' => {
          'image_tag' => 'alpine'
        }
      )
  }

  it {
    should contain_profile__kubernetes__apply('reports/secret.yaml on minikube')
      .with(
        'context'    => 'minikube',
        'parameters' => {
          'storage_account_name' => 'c3RvcmFnZV9hY2NvdW50X25hbWU=',
          'storage_account_key' => 'c3RvcmFnZV9hY2NvdW50X2tleQ=='
        }
      )
  }

  it {
    should contain_profile__kubernetes__apply('reports/ingress-tls.yaml on minikube')
      .with(
        'context'    => 'minikube',
        'parameters' => {
          'url'     => 'reports.jenkins.io',
          'aliases' => [
            'reports.jenkins-ci.org'
          ]

        }
      )
  }
  it { should contain_profile__kubernetes__reload('reports pods on minikube') }
end
