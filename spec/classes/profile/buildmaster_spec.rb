require 'spec_helper'

describe 'profile::buildmaster' do
  let(:fqdn) { 'rspec.jenkins.io' }
  let(:params) do
    {
      :ci_fqdn => fqdn,
    }
  end

  context 'Jenkins configuration' do
    it { should contain_class 'jenkins' }

    # https://issues.jenkins-ci.org/browse/INFRA-916
    context 'as a Docker container' do
      it { should contain_package('jenkins').with_ensure('absent') }
      it { should contain_file('/var/lib/jenkins').with_ensure('directory') }
      it { should contain_class 'profile::docker' }

      it 'should define a suitable docker::run' do
        expect(subject).to contain_docker__run('jenkins').with({
          :pull_on_start => true,
          :volumes => ['/var/lib/jenkins:/var/jenkins_home'],
        })
      end
    end

    # Resources which ensure that we can run our local CLI scripting
    context 'Local CLI access' do
      it { should contain_file('/var/lib/jenkins/init.groovy.d').with_ensure(:directory) }
      it { should contain_file('/var/lib/jenkins/.ssh').with_ensure(:directory) }

      context 'init.groovy.d' do
        it { should contain_file('/var/lib/jenkins/init.groovy.d/enable-ssh-port.groovy') }
        it { should contain_file('/var/lib/jenkins/init.groovy.d/set-up-git.groovy') }
        it { should contain_file('/var/lib/jenkins/init.groovy.d/terraform-credentials.groovy') }
      end
    end
  end


  # Key needed for k8s management
  it { should contain_file('/var/lib/jenkins/.ssh/azure_k8s') }

  context 'JNLP' do
    it 'should open the JNLP port in the firewall' do
      expect(subject).to contain_firewall('803 Expose JNLP port').with({
        :port => 50000,
        :proto => 'tcp',
        :action => 'accept',
      })
    end
  end


  context 'with letsencrypt => false' do
    let(:environment) { 'production' }
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
    it { should contain_class 'apache::mod::headers' }

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
