require 'spec_helper'

describe 'profile::usage' do
  it { expect(subject).to contain_class 'profile::usage' }

  context 'mounted volume setup' do
    let(:volume) { '/srv/usage' }
    it { expect(subject).to contain_class 'lvm' }
    it { expect(subject).to contain_class 'stdlib' }
    it { expect(subject).to contain_package 'lvm2' }
  end

  context 'apache setup' do
    let(:params) do
      {
        :docroot => '/tmp/rspec-docroot',
      }
    end

    it { expect(subject).to contain_class 'apache' }
    it { expect(subject).to contain_class 'profile::accounts' }
    it { expect(subject).to contain_class 'profile::apachemisc' }
    it { expect(subject).to contain_class 'profile::firewall' }
    it { expect(subject).to contain_class 'profile::letsencrypt' }

    it 'should contain File[$docroot]' do
      expect(subject).to contain_file(params[:docroot]).with({
        :ensure => :directory,
        :require => 'Package[httpd]',
      })
    end

    it 'should contain File[usage-stats.js]' do
      expect(subject).to contain_file('usage-stats.js').with({
        :ensure => :file,
        :path => "#{params[:docroot]}/usage-stats.js",
        :require => "File[#{params[:docroot]}]",
      })
    end


    it 'should contain a logging directory' do
      expect(subject).to contain_file('/var/log/apache2/usage.jenkins.io').with({
        :ensure => :link,
        :target => '/srv/bigger-usage/apache-logs',
      })
    end

    it 'usage.jenkins.io vhost' do
      expect(subject).to contain_apache__vhost('usage.jenkins.io').with({
        :port => 443,
        :ssl => true,
        :docroot => params[:docroot],
        :options => 'Indexes FollowSymLinks MultiViews',
        :override => ['All'],
      })
    end

    it 'usage.jenkins.io unsecured vhost' do
      expect(subject).to contain_apache__vhost('usage.jenkins.io unsecured').with({
        :port => 80,
        :ssl => false,
        :docroot => params[:docroot],
        :options => 'Indexes FollowSymLinks MultiViews',
        :override => ['All'],
      })
    end

    it 'usage.jenkins-ci.org' do
      expect(subject).to contain_apache__vhost('usage.jenkins-ci.org').with({
        :port => 443,
        :ssl => true,
        :docroot => params[:docroot],
        :ssl_key   => '/etc/apache2/legacy_cert.key',
        :ssl_chain => '/etc/apache2/legacy_chain.crt',
        :ssl_cert  => '/etc/apache2/legacy_cert.crt',
        :redirect_dest => 'https://usage.jenkins.io/',
      })
    end

    context 'in a production environment' do
      let(:fqdn) { 'usage.jenkins.io' }
      let(:environment) { 'production' }

      it { expect(subject).to contain_letsencrypt__certonly(fqdn) }

      it 'should configure the letsencrypt ssl keys on the vhost' do
        expect(subject).to contain_apache__vhost(fqdn).with({
          :servername => fqdn,
          :port => 443,
          :ssl_key => "/etc/letsencrypt/live/#{fqdn}/privkey.pem",
          :ssl_cert => "/etc/letsencrypt/live/#{fqdn}/fullchain.pem",
        })
      end
    end
  end

  context 'usagestats account support' do
    let(:params) do
      {
        :user => 'rspecuser',
        :group => 'rspecuser',
      }
    end

    it 'should set up the home dir' do
      # This path is legacy :/
      expect(subject).to contain_file("#{params[:user]}_home").with({
        :ensure => :directory,
        :owner => params[:user],
        :path => '/srv/bigger-usage',
      })
    end

    it { expect(subject).to contain_user(params[:user]) }
    it { expect(subject).to contain_group(params[:user]) }

    it 'should have the usage public key in authorized keys' do
      expect(subject).to contain_ssh_authorized_key('usage').with({
        :user => params[:user],
        :type => 'ssh-rsa',
      })
    end
  end

  context 'legacy support' do
    let(:params) do
      {
        :group => 'rspeclegacygroup',
      }
    end

    it 'should symlink /var/log/apache2/usage.jenkins-ci.org' do
      expect(subject).to contain_file('/var/log/apache2/usage.jenkins-ci.org').with({
        :ensure => :link,
        :target => '/var/log/apache2/usage.jenkins.io',
      })
    end

    it 'should symlink /var/log/usage-stats to /srv/usage' do
      expect(subject).to contain_file('/var/log/usage-stats').with({
        :ensure => :link,
        :target => '/srv/bigger-usage/usage-stats',
      })
    end

    it { expect(subject).to contain_user('kohsuke') }
  end
end
