require 'spec_helper'

describe 'profile::kubernetes::resources::jenkinsio' do
  let (:params) do
    {
        :url           => 'www.jenkins.test',
        :image_tag     => 'latest',
        :aliases       => ['www.jenkins-ci.test'],
        :storage_account_key => 'storage_account_key',
        :storage_account_name => 'storage_account_name'
    }
  end
  it { should contain_class('stdlib')}
  it { should contain_class('profile::kubernetes::params') }
  it { should contain_class('profile::kubernetes::kubectl') }

  it { should contain_file("/home/k8s/resources/jenkinsio").with(
    :ensure => 'directory',
    :owner  => 'k8s'
    )
  }
  it { should contain_profile__kubernetes__apply('jenkinsio/service.yaml')}

  it { should contain_profile__kubernetes__apply('jenkinsio/deployment.yaml').with(
    :parameters => {
      'image_tag' => 'latest'
      }
    )
  }

  it { should contain_profile__kubernetes__apply('jenkinsio/secret.yaml').with(
    :parameters => {
      'storage_account_name' => 'c3RvcmFnZV9hY2NvdW50X25hbWU=',
      'storage_account_key' => 'c3RvcmFnZV9hY2NvdW50X2tleQ=='
      }
    )
  }

  it { should contain_profile__kubernetes__apply('jenkinsio/ingress-tls.yaml').with(
    :parameters => {
      'url'     => 'www.jenkins.test',
      'aliases' => ['www.jenkins-ci.test']
      }
    )
  }
  it { should contain_profile__kubernetes__reload('jenkinsio pods')}
end
