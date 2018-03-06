require 'spec_helper'

describe 'profile::bind' do
  it { should contain_class 'firewall' }

  context 'docker bind setup' do
    it { should contain_class 'profile::docker' }
    it { should contain_service 'docker-bind' }
    it { should contain_docker__image 'jenkinsciinfra/bind' }
  end

  context 'bind configuration' do
    it 'should fully manage /etc/bind/local' do
      expect(subject).to contain_file('/etc/bind/local').with({
      :ensure => 'directory',
      :purge  => true,
      })
    end

    it { should contain_exec 'sighup-named' }

    it { should contain_file('/etc/bind/local/named.conf.local') }

    context 'zones' do
      [
        'jenkins-ci.org',
        'jenkins.io',
      ].each do |zone|
        it "should have a zonefile for #{zone}" do
          expect(subject).to contain_file("/etc/bind/local/#{zone}.zone").with({
            :ensure => :present,
            :notify => ['Service[docker-bind]', 'Exec[sighup-named]'],
            :require => 'File[/etc/bind/local]',
          })
        end
      end
    end
  end

  context 'DNS monitoring' do
    it 'should contain a datadog_check for DNS' do
      expect(subject).to contain_file('datadog-dns-check-config').with({
        :path => '/etc/datadog-agent/conf.d/dns_check.yaml',
        :ensure => :present,
      })
    end
  end
end
