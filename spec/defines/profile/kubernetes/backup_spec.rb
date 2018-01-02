require 'spec_helper'

describe 'profile::kubernetes::backup' do
  let(:title) { 'accountapp-tls on minikube' }
  let(:params) do
    {
      'bin' => '/home/k8s/.bin',
      'context' => 'minikube',
      'resource' => 'accountapp-tls',
      'user' => 'k8s',
      'type' => 'secret'
    }
  end
  it { should contain_class 'profile::kubernetes::params' }

  it {
    should contain_cron('Backup secret/accountapp-tls from minikube')
      .with(
        'ensure'  => 'present',
        'user'    => 'k8s',
        'name'    => 'Backup secret/accountapp-tls from minikube',
        'command' => '/home/k8s/.bin/backup.sh minikube accountapp-tls secret',
        'hour'    => '3',
        'minute'  => '13'
      )
  }
end
