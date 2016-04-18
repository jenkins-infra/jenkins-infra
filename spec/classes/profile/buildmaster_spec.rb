require 'spec_helper'

describe 'profile::buildmaster' do
  let(:fqdn) { 'rspec.jenkins.io' }
  let(:params) do
    {
      :ci_fqdn => fqdn,
    }
  end

  it { should contain_class 'jenkins' }


  context 'with letsencrypt => false' do
    let(:facts) { {:environment => 'production' } }
    let(:params) do
      {
        :ci_fqdn => fqdn,
        :letsencrypt => false,
      }
    end

    it { should_not contain_class 'profile::letsencrypt' }
    it { should_not contain_letsencrypt__certonly(fqdn) }
  end

  context 'apache configuration' do
    it { should contain_class 'apache' }
    it { should contain_class 'profile::apachemisc' }
    it { should contain_class 'profile::letsencrypt' }
    it { should contain_class 'apache::mod::proxy' }

    context 'vhosts' do
      it 'should contain a vhost with ssl' do
        expect(subject).to contain_apache__vhost(fqdn).with({
          :servername => fqdn,
          :port => 443,
          :proxy_preserve_host => true,
          :proxy_pass => [
            {
              'path' => '/',
              'url' => 'http://localhost:8080/',
              'keywords' => ['nocanon'],
              'reverse_urls' => ['http://localhost:8080/'],
            },
          ],
        })
      end

      it 'should contain a vhost that promotes non-SSL to SSL' do
        expect(subject).to contain_apache__vhost("#{fqdn} unsecured").with({
          :servername => fqdn,
          :port => 80,
          :redirect_status => 'permanent',
          :redirect_dest => "https://#{fqdn}/",
        })
      end
    end

    context 'when running in production' do
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

  context 'jenkins master configuration' do
    it 'should contain zero executors for security' do
      expect(subject).to contain_class('jenkins').with({
        :executors => 0,
      })
    end

    it 'should default to LTS' do
      expect(subject).to contain_class('jenkins').with({
        :lts => true,
      })
    end
  end

  context 'with plugins' do
    let(:params) do
      {
        :plugins => ['workflow-aggregator',]
      }
    end

    it { should contain_profile__jenkinsplugin('workflow-aggregator') }
    it { should contain_exec('install-plugin-workflow-aggregator') }
  end

  context 'firewall rules' do
    it { should contain_class 'profile::firewall' }

    it 'should have a CLI port rule' do
      expect(subject).to contain_firewall('108 Jenkins CLI port').with({
        :port => 47278,
        :action => :accept,
      })
    end

    it 'should ensure nothing talks directly to Jenkins' do
      expect(subject).to contain_firewall('801 Allow Jenkins web access only on localhost').with({
        :port => 8080,
        :action => :accept,
        :iniface => 'lo',
      })

      expect(subject).to contain_firewall('802 Block external Jenkins web access').with({
        :port => 8080,
        :action => :drop,
      })

    end

    it 'should allow CLI SSH on 22222' do
      expect(subject).to contain_firewall('810 Jenkins CLI SSH').with({
        :port => 22222,
        :action => :accept,
      })
    end
  end
end
