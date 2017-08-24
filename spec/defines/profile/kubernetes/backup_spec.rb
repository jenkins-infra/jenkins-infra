require 'spec_helper'


describe 'profile::kubernetes::backup' do
    let (:title) { 'accountapp-tls'}
    let (:params) do
      {
        :user       => 'k8s',
        :bin        => '/home/k8s/.bin',
        :type       => 'secret',
        :clusters   => [{
          'clustername' =>  'clusterexample1',
        }]

      }
    end
    it { should contain_class 'profile::kubernetes::params' }

    it { should contain_cron('Backup secret/accountapp-tls from clusterexample1').with(
      :ensure  => 'present',
      :user    => 'k8s',
      :name    => 'Backup secret/accountapp-tls from clusterexample1',
      :command => '/home/k8s/.bin/backup.sh clusterexample1 accountapp-tls secret',
      :hour    => '3',
      :minute  => '13'
      )
    }
end
