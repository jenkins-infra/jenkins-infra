require 'spec_helper'


describe 'profile::updatesite' do
  let(:fqdn) { 'updates.jenkins.io' }
  let(:legacy_fqdn) { 'updates.jenkins-ci.org' }

  it { expect(subject).to contain_class 'profile::updatesite' }
  it { expect(subject).to contain_class 'profile::firewall' }

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

    it { expect(subject).to contain_ssh_authorized_key('updatesite-key').with_key(params[:ssh_pubkey]) }
    it { expect(subject).to contain_user('www-data').with_purge_ssh_keys(true) }

    it 'should ensure the /var/www permissions are correct for SSH auth' do
      expect(subject).to contain_file('/var/www').with({
        :ensure => :directory,
        :mode   => '0755',
      })
    end
  end

  context 'apache setup' do
    it { expect(subject).to contain_class 'apache' }
    it { expect(subject).to contain_class 'profile::apachemisc' }
    it { expect(subject).to contain_class 'profile::letsencrypt' }

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

      it { expect(subject).to contain_file("/var/log/apache2/#{legacy_fqdn}").with_ensure(:directory) }

      it 'should contain a vhost on port 80/HTTP for legacy_fqdn' do
        expect(subject).to contain_apache__vhost("#{legacy_fqdn} unsecured").with({
          :servername => legacy_fqdn,
          :port => 80,
          :docroot => "/var/www/#{fqdn}",
          :redirect_status => nil,
          :redirect_dest => nil,
          :override  => ['All'],
        })
      end

      it 'should contain a vhost with ssl on port 443/HTTPs for legacy_fqdn' do
        expect(subject).to contain_apache__vhost(legacy_fqdn).with({
          :servername => legacy_fqdn,
          :port => 443,
          :ssl => true,
          :docroot => "/var/www/#{fqdn}",
          :override  => ['All'],
        })
      end
    end
  end

  context 'when running in production with letsencrypt' do
    let(:environment) { 'production' }

    it { expect(subject).to contain_letsencrypt__certonly(fqdn) }

    it 'should configure the letsencrypt ssl keys on the main vhost' do
      expect(subject).to contain_apache__vhost(fqdn).with({
        :servername => fqdn,
        :port => 443,
        :ssl_key => "/etc/letsencrypt/live/#{fqdn}/privkey.pem",
        :ssl_cert => "/etc/letsencrypt/live/#{fqdn}/cert.pem",
        :ssl_chain => "/etc/letsencrypt/live/#{fqdn}/chain.pem",
      })
    end

    it { expect(subject).to contain_letsencrypt__certonly(legacy_fqdn) }

    it 'should configure the letsencrypt ssl keys on the legacy_fqdn vhost' do
      expect(subject).to contain_apache__vhost(legacy_fqdn).with({
        :servername => legacy_fqdn,
        :port => 443,
        :ssl_key => "/etc/letsencrypt/live/#{legacy_fqdn}/privkey.pem",
        :ssl_chain => "/etc/letsencrypt/live/#{legacy_fqdn}/chain.pem",
        :ssl_cert => "/etc/letsencrypt/live/#{legacy_fqdn}/cert.pem",
      })
    end
  end

  context 'when running in production with manual certificates' do
    let(:params) {
      {
        :certificates => {
          "#{fqdn}" => {
            'privkey' => 'update private key',
            'cert'  => 'updates certificate',
            'chain' => 'update chain',
          },
          "#{legacy_fqdn}" => {
            'privkey' => 'legacy private key',
            'cert'  => 'legacy certificate',
            'chain' => 'legacy chain',
          },
        }
      }
    }

    it 'should configure the manual ssl keys on the main vhost' do
      expect(subject).to contain_apache__vhost(fqdn).with({
        :servername => fqdn,
        :port => 443,
        :ssl_key => "/etc/apache2/ssl/#{fqdn}/privkey.pem",
        :ssl_cert => "/etc/apache2/ssl/#{fqdn}/cert.pem",
        :ssl_chain => "/etc/apache2/ssl/#{fqdn}/chain.pem",
      })
    end

    it 'should configure the manual ssl keys on the legacy_fqdn vhost' do
      expect(subject).to contain_apache__vhost(legacy_fqdn).with({
        :servername => legacy_fqdn,
        :port => 443,
        :ssl_key => "/etc/apache2/ssl/#{legacy_fqdn}/privkey.pem",
        :ssl_chain => "/etc/apache2/ssl/#{legacy_fqdn}/chain.pem",
        :ssl_cert => "/etc/apache2/ssl/#{legacy_fqdn}/cert.pem",
      })
    end
  end
end
