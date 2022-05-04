require 'spec_helper'

describe 'profile::buildmaster' do
  let(:fqdn) { 'rspec.jenkins.io' }
  let(:params) do
    {
      :ci_fqdn => fqdn,
    }
  end

  context 'Jenkins configuration' do
    it { is_expected.to contain_user('jenkins').with(
        'ensure' => 'present',
        'home'   => '/var/lib/jenkins'
      )
    }

    it { is_expected.to contain_group('jenkins').with(
        'ensure' => 'present',
      )
    }

    # https://issues.jenkins-ci.org/browse/INFRA-916
    context 'as a Docker container' do
      it { should contain_file('/var/lib/jenkins').with_ensure('directory') }
      it { should contain_class 'profile::docker' }

      it 'should define a suitable docker::run' do
        expect(subject).to contain_docker__run('jenkins').with({
          :pull_on_start => true,
          :volumes => ['/var/lib/jenkins:/var/jenkins_home'],
        })
      end
    end

    context 'Init groovy script' do
      it { is_expected.to contain_file('/var/lib/jenkins/init.groovy.d').with(
          'ensure' => 'directory',
          'purge'  => 'true',
          'recurse' => 'true'
        )
      }
      context "By default: Init Groovy directory" do
        it { is_expected.not_to contain_file('/var/lib/jenkins/init.groovy.d/enable-ssh-port.groovy')}
        it { is_expected.not_to contain_file('/var/lib/jenkins/init.groovy.d/set-up-git.groovy')}
        it { is_expected.not_to contain_file('/var/lib/jenkins/init.groovy.d/pipeline-configuration.groovy')}
      end
    end

    context 'JCasC' do
      it { is_expected.to contain_file('/var/lib/jenkins/casc.d').with('ensure' => 'directory')}
      it { is_expected.to contain_file('/var/lib/jenkins/casc.d/clouds.yaml')}
      it { should contain_exec('install-plugin-configuration-as-code') }
      it { should contain_exec('perform-jcasc-reload') }
      it { should contain_exec('safe-restart-jenkins') }
    end


    # Resources which ensure that we can run our local CLI scripting
    context 'Local CLI access' do
      it { is_expected.to contain_file('/var/lib/jenkins/.ssh') }
    end
  end


  # Key needed for k8s management
  it { should contain_file('/var/lib/jenkins/.ssh/azure_k8s') }

  context 'JNLP' do
    it 'should open the JNLP port in the firewall' do
      expect(subject).to contain_firewall('803 Expose JNLP port').with({
        :dport => 50000,
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

    it 'should ensure nothing talks directly to Jenkins' do
      expect(subject).to contain_firewall('801 Allow Jenkins web access only on localhost').with({
        :dport => 8080,
        :action => :accept,
        :iniface => 'lo',
      })

      expect(subject).to contain_firewall('802 Block external Jenkins web access').with({
        :dport => 8080,
        :action => :drop,
      })

    end
  end
end
