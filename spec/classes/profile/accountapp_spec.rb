require 'spec_helper'

describe 'profile::accountapp' do
  it { should contain_class 'firewall' }

  context 'accountapp configuration' do
    it do
      should contain_file('/etc/accountapp').with({
        :ensure => :directory,
      })
    end

    it { should contain_file('/etc/accountapp/config.properties').with_ensure(:file) }
  end

  context 'accountapp docker image' do
    it { should contain_class 'profile::docker' }

    let(:tag) { 'buildRspec' }
    let(:params) do
      {
        :image_tag => tag,
      }
    end

    it 'should have the right image' do
      expect(subject).to contain_docker__image('jenkinsciinfra/account-app').with({
        :image_tag => tag,
      })
    end

    it 'should run the docker image' do
      expect(subject).to contain_docker__run('account-app').with({
        :command => nil,
        :image => "jenkinsciinfra/account-app:#{tag}",
      })
    end
  end

  context 'apache setup' do
    it { should contain_class 'apache' }
    it { should contain_class 'letsencrypt' }
    it { should contain_class 'profile::apache-misc' }

    it 'should have a vhost' do
      expect(subject).to contain_apache__vhost('accounts.jenkins.io').with({
        :port => 443,
        :ssl  => true,
      })
    end

    it 'should have a non-TLS vhost that redirects' do
      expect(subject).to contain_apache__vhost('accounts.jenkins.io unsecured').with({
        :port => 80,
        :redirect_status => 'permanent',
        :redirect_dest => 'https://accounts.jenkins.io/'
      })
    end


    it 'should obtain certificates' do
      expect(subject).to contain_letsencrypt__certonly('accounts.jenkins.io').with({
        :plugin => 'apache',
        :domains => ['accounts.jenkins.io', 'accounts.jenkins-ci.org'],
      })
    end

    it 'should use a staging host for letsencrypt' do
      expect(subject).to contain_class('letsencrypt').with({
          :config => {
            "email" => 'tyler@monkeypox.org',
            "server" => "https://acme-staging.api.letsencrypt.org/directory",
          },
      })
    end
  end
end
