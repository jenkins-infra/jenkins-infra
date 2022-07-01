require 'spec_helper'


describe 'profile::updatesite' do
  let(:fqdn) { 'updates.jenkins.io' }

  it { should contain_class 'profile::updatesite' }
  it { should contain_class 'profile::firewall' }

  it 'should give www-data a shell' do
    expect(subject).to contain_user('www-data').with({
      :shell => '/bin/bash',
    })
  end

  context 'with ssh_pubkey provided' do
    let(:params) do
      {
        :ssh_pubkey => 'rspeckey',
      }
    end

    it { should contain_ssh_authorized_key('updatesite-key').with_key(params[:ssh_pubkey]) }
    it { should contain_user('www-data').with_purge_ssh_keys(true) }

    it 'should ensure the /var/www permissions are correct for SSH auth' do
      expect(subject).to contain_file('/var/www').with({
        :ensure => :directory,
        :mode   => '0755',
      })
    end
  end

  context 'apache setup' do
    it { should contain_class 'apache' }
    it { should contain_class 'profile::apachemisc' }
    it { should contain_class 'profile::letsencrypt' }

    context 'virtual hosts' do
      it 'should contain a vhost with ssl' do
        expect(subject).to contain_apache__vhost(fqdn).with({
          :servername => fqdn,
          :port => 443,
          :docroot => "/var/www/#{fqdn}",
          :override  => ['All'],
        })
      end

      it 'should contain a vhost on port 80/HTTP' do
        expect(subject).to contain_apache__vhost("#{fqdn} unsecured").with({
          :servername => fqdn,
          :port => 80,
          :docroot => "/var/www/#{fqdn}",
          :redirect_status => nil,
          :redirect_dest => nil,
          :override  => ['All'],
        })
      end


      it { should contain_file('/var/log/apache2/updates.jenkins-ci.org').with_ensure(:directory) }

      it 'should contain a vhost on port 80/HTTP for updates.jenkins-ci.org' do
        expect(subject).to contain_apache__vhost('updates.jenkins-ci.org unsecured').with({
          :servername => 'updates.jenkins-ci.org',
          :port => 80,
          :docroot => "/var/www/#{fqdn}",
          :redirect_status => nil,
          :redirect_dest => nil,
          :override  => ['All'],
        })
      end

      it 'should contain a vhost on port 443/HTTPs for updates.jenkins-ci.org' do
        expect(subject).to contain_apache__vhost('updates.jenkins-ci.org').with({
          :servername => 'updates.jenkins-ci.org',
          :port => 443,
          :ssl_key => '/etc/letsencrypt/live/updates.jenkins-ci.org/privkey.pem',
          :ssl_chain => '/etc/letsencrypt/live/updates.jenkins-ci.org/chain.pem',
          :ssl_cert => '/etc/letsencrypt/live/updates.jenkins-ci.org/cert.pem',
          :ssl => true,
          :docroot => "/var/www/#{fqdn}",
          :override  => ['All'],
        })
      end
    end
  end

  context 'when running in production' do
    let(:environment) { 'production' }
    it { should contain_letsencrypt__certonly(fqdn) }

    it 'should configure the letsencrypt ssl keys on the vhost' do
      expect(subject).to contain_apache__vhost(fqdn).with({
        :servername => fqdn,
        :port => 443,
        :ssl_key => "/etc/letsencrypt/live/#{fqdn}/privkey.pem",
        :ssl_cert => "/etc/letsencrypt/live/#{fqdn}/cert.pem",
        :ssl_chain => "/etc/letsencrypt/live/#{fqdn}/chain.pem",
      })
    end
  end
end
