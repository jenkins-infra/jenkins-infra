require 'spec_helper'

describe 'profile::letsencrypt' do
  context 'default setup uses HTTP-01 with staging' do
    it {
      expect(subject).to contain_package('python3.8')
      expect(subject).to contain_package('python3-pip')
      expect(subject).to contain_package('libaugeas0')

      expect(subject).to contain_exec('Install certbot').with({
        :command => '/usr/bin/python3.8 -m pip install --upgrade pyopenssl certbot==1.32.0 acme==1.32.0',
      })

      expect(subject).to contain_exec('Install certbot-apache plugin').with({
        :command => '/usr/bin/python3.8 -m pip install --upgrade certbot-apache==1.32.0',
        :unless  => '/usr/local/bin/certbot plugins --text 2>&1 | /bin/grep --quiet apache',
      })

      expect(subject).to contain_class('letsencrypt').with_config({
        'email'                => 'tyler@monkeypox.org',
        'server'               => 'https://acme-staging-v02.api.letsencrypt.org/directory',
        'authenticator'        => 'apache',
        'preferred-challenges' => 'http',
      }).with_package_ensure('absent').with_configure_epel(false)
      expect(subject).to contain_file('/etc/letsencrypt/azure.ini').with({
        :ensure  => 'absent',
      })
    }
  end

  context 'custom setup with Azure DNS-01 challenge and production environment' do
    let(:environment) { 'production' }
    let(:params) do
      {
        :plugin => 'dns-azure',
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
      expect(subject).to contain_package('python3.8')
      expect(subject).to contain_package('python3-pip')

      expect(subject).to contain_exec('Install certbot').with({
        :command => '/usr/bin/python3.8 -m pip install --upgrade pyopenssl certbot==1.32.0 acme==1.32.0',
      })

      expect(subject).not_to contain_exec('Install certbot-apache plugin').with({
        :command => '/usr/bin/python3.8 -m pip install --upgrade certbot-apache==1.32.0',
        :unless  => '/usr/local/bin/certbot plugins --text 2>&1 | /bin/grep --quiet apache',
      })

      expect(subject).to contain_exec('Install certbot-dns-azure plugin').with({
        :command => '/usr/bin/python3.8 -m pip install --upgrade certbot-dns-azure',
        :unless  => '/usr/local/bin/certbot plugins --text 2>&1 | /bin/grep --quiet dns-azure',
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
