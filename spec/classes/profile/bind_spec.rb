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

    it { should contain_file('/etc/bind/local/named.conf.local') }

    context 'zones' do
      it { should contain_file('/etc/bind/local/jenkins-ci.org.zone') }
      it { should contain_file('/etc/bind/local/jenkins.io.zone') }
    end
  end
end
