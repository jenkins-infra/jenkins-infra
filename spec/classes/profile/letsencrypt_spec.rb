require 'spec_helper'

describe 'profile::letsencrypt' do
  context 'default setup uses HTTP-01 with staging' do
    it {
      expect(subject).to contain_class 'snap'
      expect(subject).to contain_package('certbot').with({
        :provider => 'snap',
        :install_options => ['classic'],
      })
      expect(subject).to contain_file('/usr/bin/certbot').with({
        :ensure => 'link',
        :source  => '/snap/bin/certbot',
        })
      expect(subject).to contain_class('letsencrypt').with_config({
        'email'                => 'tyler@monkeypox.org',
        'server'               => 'https://acme-staging-v02.api.letsencrypt.org/directory',
        'authenticator'        => 'apache',
        'preferred-challenges' => 'http',
      }).with_package_ensure('absent').with_configure_epel(false)
      expect(subject).to contain_package('certbot-dns-azure').with({
        :ensure  => 'absent',
      })
      expect(subject).to contain_file('/etc/letsencrypt/azure.ini').with({
        :ensure  => 'absent',
      })
    }
  end

  context 'custom setup with Azure DNS-01 challenge and production environment' do
    let(:environment) { 'production' }
    let(:params) do
      {
        :dns_azure => {
          :sp_client_id => "sp-app-id",
          :sp_client_secret => "token",
          :tenant_id => "tenant-id",
          :zones => {
            :localhost => "/subscriptions/xxx/AzureDNS/localhost",
            :"app.localhost" =>  "/subscriptions/xxx/AzureDNS/localhost",
          },
        },
      }
    end

    it {
      expect(subject).to contain_class 'snap'
      expect(subject).to contain_package('certbot').with({
        :provider => 'snap',
        :install_options => ['classic'],
      })
      expect(subject).to contain_package('certbot-dns-azure').with({
        :provider => 'snap',
      })
      expect(subject).to contain_snap_conf('trust plugin with root dns-azure').with({
        :ensure => 'present',
        :conf   => 'trust-plugin-with-root',
        :value  => 'ok',
        :snap   => 'certbot',
      })
      expect(subject).to contain_file('/usr/bin/certbot').with({
        :ensure => 'link',
        :source  => '/snap/bin/certbot',
      })
      expect(subject).to contain_exec('Connect certbot with certbot-dns-azure plugin').with({
        :command => '/usr/bin/snap connect certbot:plugin certbot-dns-azure',
        :unless  => '/snap/bin/certbot plugins --text | /bin/grep "dns-azure" 2>/dev/null',
      })
      expect(subject).to contain_file('/etc/letsencrypt/azure.ini').with({
        :ensure  => 'file',
        :owner   => 'root',
        :group   => 'root',
        :mode    => '0600',
      })
      expect(subject).to contain_class('letsencrypt').with_config({
        'email'                => 'tyler@monkeypox.org',
        'server'               => 'https://acme-v02.api.letsencrypt.org/directory', # Due to production environment set up
        'authenticator'        => 'dns-azure',
        'preferred-challenges' => 'dns',
        'dns-azure-config'     => '/etc/letsencrypt/azure.ini',
      }).with_package_ensure('absent').with_configure_epel(false)
    }

    it 'should specify the custom config + DNS-01 setup for letsencrypt' do
      expect(subject).to contain_class('letsencrypt')
    end
  end
end
