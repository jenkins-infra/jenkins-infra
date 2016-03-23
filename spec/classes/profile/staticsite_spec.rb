require 'spec_helper'

describe 'profile::staticsite' do
  it { should contain_class 'apache' }

  # We need unzip in order to extract our archives, duh
  it { should contain_package('zip').with(:ensure => 'present') }

  describe 'the filesystem' do
    it { should contain_file('/srv/jenkins.io/archives').
                  with(:ensure => 'directory') }

    it { should contain_file('/srv/jenkins.io/deploy-site').with({
      :ensure => 'present',
      :owner  => 'site-deployer',
    }) }
  end

  describe 'deployer setup' do
    let(:ssh_key) { 'some-made-up-ssh-key' }
    let(:params) { { :deployer_ssh_key => ssh_key } }

    it 'contains a deployer account setup' do
      expect(subject).to contain_account('site-deployer').with(
        :ssh_key => ssh_key,
        :shell   => '/usr/lib/sftp-server',
      )
    end

    it 'adds sftp-server as a valid shell' do
      expect(subject).to contain_file_line('sftp-server shell').with(
        :line => '/usr/lib/sftp-server',
      )
    end
  end

  context 'apache setup' do
    it { should contain_class 'letsencrypt' }
    it { should contain_apache__vhost('beta.jenkins-ci.org')
                .with(:docroot => '/srv/jenkins.io/current') }

    it { should contain_apache__vhost('jenkins.io')
                .with(:docroot => '/srv/jenkins.io/beta') }

    it 'should upgrade non-TLS to TLS' do
      expect(subject).to contain_apache__vhost('jenkins.io unsecured').with({
        :port => 80,
        :redirect_status => 'permanent',
        :redirect_dest => 'https://jenkins.io/'
      })
    end
  end

  it 'should invoke deploy-site in a cron' do
    expect(subject).to contain_cron('deploy-site').with({
      :ensure => 'present',
      :user => 'site-deployer',
    })
  end
end
