require 'spec_helper'

describe 'profile::kubernetes::resources::pluginsite' do
  let(:params) do
    {
      'image_tag' => 'latest'
    }
  end

  it { should contain_class('profile::kubernetes::params') }
  it { should contain_class('profile::kubernetes::kubectl') }
  it { should contain_class('profile::kubernetes::resources::lego') }
  it { should contain_class('profile::kubernetes::resources::nginx') }

  it {
    should contain_file('/home/k8s/resources/minikube/pluginsite').with(
      'ensure' => 'directory',
      'owner'  => 'k8s'
    )
  }

  it { should contain_profile__kubernetes__apply('pluginsite/service.yaml on minikube') }

  it {
    should contain_profile__kubernetes__apply('pluginsite/deployment.yaml on minikube').with(
      'context'    => 'minikube',
      'parameters' => {
        'image_tag' => 'latest'
      }
    )
  }
  it {
    should contain_profile__kubernetes__apply('pluginsite/configmap.yaml on minikube').with(
      'context'    => 'minikube',
      'parameters' => {
        'url' => 'https://plugins.jenkins.io/api',
        'data_file_url' => 'https://ci.jenkins.io/job/Infra/job/plugin-site-api/job/generate-data/lastSuccessfulBuild/artifact/plugins.json.gzip'
      }
    )
  }
  it {
    should contain_profile__kubernetes__apply('pluginsite/ingress-tls.yaml on minikube').with(
      'context'    => 'minikube',
      'parameters' => {
        'url' => 'plugins.jenkins.io',
        'aliases' => ['plugins.azure.jenkins.io']
      }
    )
  }
  it { should contain_profile__kubernetes__reload('pluginsite pods on minikube') }
  it { should contain_profile__kubernetes__backup('pluginsite-tls on minikube') }
end
