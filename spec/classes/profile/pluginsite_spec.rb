require 'spec_helper'


describe 'profile::pluginsite' do
  it { should contain_class 'profile::pluginsite' }

  it { should contain_class 'profile::docker' }

  context 'Docker configuration' do
    it { should contain_docker__image 'jenkinsciinfra/plugin-site' }

    context 'with a non-default $image_tag' do
      let(:params) do
        {
          :image_tag => 'rspec',
        }
      end

      it { should contain_docker__image('jenkinsciinfra/plugin-site').with_image_tag('rspec') }
    end

    context 'running the container' do
      it 'should create docker::run' do
        expect(subject).to contain_docker__run('pluginsite').with({
          :ports => ['8080:8080', '5000:5000'],
        })
      end
    end
  end

  context 'Apache configuration' do
    it { should contain_file('/srv/pluginsite').with_ensure(:directory) }

    context 'plugins.jenkins.io virtual host' do
      it 'should have a vhost' do
        expect(subject).to contain_apache__vhost('plugins.jenkins.io').with({
          :port => 443,
          :ssl  => true,
        })
      end

      it 'should have a non-TLS vhost that redirects' do
        expect(subject).to contain_apache__vhost('plugins.jenkins.io unsecured').with({
          :port => 80,
          :redirect_status => 'permanent',
          :redirect_dest => 'https://plugins.jenkins.io/'
        })
      end
    end
  end

  context 'in production' do
    let(:facts) do
      {
        :environment => 'production'
      }
    end

    it 'should obtain certificates' do
      expect(subject).to contain_letsencrypt__certonly('plugins.jenkins.io').with({
        :plugin => 'apache',
        :domains => ['plugins.jenkins.io'],
      })
    end

    it 'should put letsencrypt certs in the vhost' do
      expect(subject).to contain_apache__vhost('plugins.jenkins.io').with({
        :ssl => true,
        :ssl_key => '/etc/letsencrypt/live/plugins.jenkins.io/privkey.pem',
        :ssl_cert => '/etc/letsencrypt/live/plugins.jenkins.io/cert.pem',
        :ssl_chain => '/etc/letsencrypt/live/plugins.jenkins.io/chain.pem',
      })
    end
  end
end
