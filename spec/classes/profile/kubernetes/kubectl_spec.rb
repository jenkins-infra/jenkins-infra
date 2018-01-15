require 'spec_helper'

describe 'profile::kubernetes::kubectl' do
  let(:pre_condition) { 'include profile::kubernetes::params' }
  let(:params) do
    {
      'clusters' => [{
        'clustername' => 'clusterexample1'
      }],
      'version' => '1.6.6'

    }
  end

  it { should contain_class 'profile::kubernetes::params' }

  it {
    should contain_user('k8s').with(
      'ensure'     => 'present',
      'home'       => '/home/k8s',
      'managehome' => true
    )
  }

  it {
    should contain_file('/home/k8s/.bin').with(
      'ensure' => 'directory',
      'owner'  => 'k8s'
    )
  }

  it {
    should contain_file('/home/k8s/resources').with(
      'ensure' => 'directory',
      'owner'  => 'k8s'
    )
  }

  it {
    should contain_file('/home/k8s/trash').with(
      'ensure' => 'directory',
      'owner'  => 'k8s'
    )
  }

  it {
    should contain_file('/home/k8s/backup').with(
      'ensure' => 'directory',
      'owner'  => 'k8s'
    )
  }

  it {
    should contain_file('/home/k8s/.kube').with(
      'ensure' => 'directory',
      'owner'  => 'k8s'
    )
  }

  it {
    should contain_file('/home/k8s/.kube/config').with(
      'ensure' => 'present',
      'owner'  => 'k8s'
    )
  }

  it {
    should contain_file('/home/k8s/.bin/backup.sh').with(
      'ensure' => 'present',
      'owner'  => 'k8s'
    )
  }

  it {
    should contain_file('/home/k8s/.bin/kubectl').with(
      'mode'   => '0755',
      'ensure' => 'present',
      'source' => 'https://storage.googleapis.com/kubernetes-release/release/v1.6.6/bin/linux/amd64/kubectl',
      'owner'  => 'k8s'
    )
  }

  it {
    should contain_file('/home/k8s/backup/clusterexample1').with(
      'ensure' => 'directory',
      'owner'  => 'k8s'
    )
  }

  it {
    should contain_file('/home/k8s/resources/clusterexample1').with(
      'ensure' => 'directory',
      'owner'  => 'k8s'
    )
  }
end
