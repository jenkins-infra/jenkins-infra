require 'spec_helper'


describe 'profile::kubernetes::delete' do
    let (:pre_condition) { 'include profile::kubernetes::params'}
    let (:title) { 'nginx/deployment.yaml'}
    let (:params) do
      {
        :resource  => 'nginx/deployment.yaml',
      }
    end
    
    it { should contain_class 'profile::kubernetes::params' }

    it { should contain_file("/home/k8s/trash/nginx").with(
      :owner  => 'k8s',
      :ensure => 'directory'
      )
    }

    it { should contain_file("/home/k8s/trash/nginx/deployment.yaml").with(
      :owner  => 'k8s',
      :ensure => 'present'
      )
    }
  
   it { should contain_file("/home/k8s/resources/nginx/deployment.yaml").with(
     :ensure => 'absent'
     )
   }

end
