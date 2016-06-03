require 'spec_helper'

describe 'profile::usage' do
  it { should contain_class 'profile::usage' }

  context 'mounted volume setup' do
    let(:volume) { '/srv/usage' }
    it { should contain_class 'lvm' }
    it { should contain_class 'stdlib' }
    it { should contain_package 'lvm2' }

    it 'should have an access log dir' do
      expect(subject).to contain_file("#{volume}/apache-logs").with({
        :ensure => :directory,
        :require => "Mount[#{volume}]",
      })
    end

    it 'should have a decrypted log dir' do
      expect(subject).to contain_file("#{volume}/usage-stats").with({
        :ensure => :directory,
        :require => "Mount[#{volume}]",
      })
    end
  end

  context 'apache setup' do
    let(:params) do
      {
        :docroot => '/tmp/rspec-docroot',
      }
    end

    it { should contain_class 'apache' }
    it { should contain_class 'profile::accounts' }
    it { should contain_class 'profile::apachemisc' }
    it { should contain_class 'profile::firewall' }
    it { should contain_class 'profile::letsencrypt' }

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
        :target => '/srv/usage/apache-logs',
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
      let(:facts) do
        {
          :environment => 'production',
        }
      end

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
        :path => '/srv/usage',
      })
    end

    it { should contain_user(params[:user]) }
    it { should contain_group(params[:user]) }
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
        :target => '/srv/usage/usage-stats',
      })
    end

    it { should contain_user('kohsuke') }

    it 'should add the `kohsuke` user to the usage group' do
      expect(subject).to contain_exec('add-kohsuke-to-usage-group').with({
        :command => "usermod -aG #{params[:group]} kohsuke",
      })
    end

    it "should have /home/kohsuke/sudo-rsync for kohsuke's old scripts" do
      expect(subject).to contain_file('/home/kohsuke/sudo-rsync').with({
        :ensure => :file,
        :content => '#!/bin/sh
exec rsync "$@"',
        :mode => '0755',
        :require => 'User[kohsuke]',
      })
    end
  end
end

