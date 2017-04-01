require 'spec_helper'


describe 'profile::kubernetes::kubectl' do
    kubectl_version = '1.5.4'
    let (:params) do
      {
        :user       => 'k8s',
        :home       => '/home/k8s',
        :bin        => '/home/k8s/.bin',
        :resources  => '/home/k8s/resources',
      }
    end
    it { should contain_class 'profile::kubernetes::params' }
    it { should contain_user('k8s').with(
        :ensure     => 'present',
        :name       => 'k8s',
        :home       => '/home/k8s',
        :managehome => true
      )
    }
    it { should contain_file('/home/k8s/resources').with(
      :ensure => 'directory',
      :owner  => 'k8s'
      )
    }
    it { should contain_file('/home/k8s/.kube').with(
          :ensure => 'directory',
          :owner  => 'k8s' 
      )
    }
    it { should contain_file('/home/k8s/.kube/config').with(
      :owner  => 'k8s',
      :ensure => 'present'
      )
    }
    it { should contain_file('/home/k8s/.bin').with(
      :ensure => 'directory',
      :owner  => 'k8s'
      )
    }
    it { should contain_file('/home/k8s/.bin/kubectl').with(
      :mode => '0755',
      :ensure => 'present',
      :source => "https://storage.googleapis.com/kubernetes-release/release/v#{kubectl_version}/bin/linux/amd64/kubectl",
      :owner => 'k8s'
      )
    }
end
