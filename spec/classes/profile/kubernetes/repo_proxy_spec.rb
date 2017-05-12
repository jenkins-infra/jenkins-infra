require 'spec_helper'

describe 'profile::kubernetes::resources::repo_proxy' do
  let (:params) do
    {
        :url           => 'repo.azure.jenkins.io',
        :image_tag     => 'latest',
        :aliases       => ['repo.azure.jenkins-ci.org'],
        :storage_account_key => 'storage_account_key',
        :storage_account_name => 'storage_account_name'
    }
  end
  it { should contain_class('stdlib')}
  it { should contain_class('profile::kubernetes::params') }
  it { should contain_class('profile::kubernetes::kubectl') }

  it { should contain_file("/home/k8s/resources/repo_proxy").with(
    :ensure => 'directory',
    :owner  => 'k8s'
    )
  }
  it { should contain_profile__kubernetes__apply('repo_proxy/service.yaml')}
  it { should contain_profile__kubernetes__apply('repo_proxy/deployment.yaml').with(
    :parameters => {
      'image_tag' => 'latest'
      }
    )

  it { should contain_profile__kubernetes__apply('repo_proxy/secret.yaml').with(
    :parameters => {
      'storage_account_name' => 'c3RvcmFnZV9hY2NvdW50X25hbWU=',
      'storage_account_key' => 'c3RvcmFnZV9hY2NvdW50X2tleQ=='
      }
    )
  }

  it { should contain_profile__kubernetes__apply('repo_proxy/ingress-tls.yaml').with(
    :parameters => {
      'url'     => 'repo.azure.jenkins.io',
      'aliases' => ['repo.azure.jenkins-ci.org']
      }
    )
  }
  it { should contain_exec('Reload repo_proxy pods').with(
    :subscribe => [ 
      Exec['apply repo_proxy/secret.yaml']
      ] 
    )
  }
end
