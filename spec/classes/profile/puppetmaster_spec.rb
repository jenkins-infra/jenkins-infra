require 'spec_helper'

describe 'profile::puppetmaster' do
  let(:pre_condition) do
    # Define our jenkins_keys class in our catalog, since it's provided by a
    # private module
    ['class jenkins_keys { }']
  end

  it { should contain_class 'jenkins_keys' }
  it { should contain_class 'profile::r10k' }

  context 'puppet.conf' do
    let(:path) { '/etc/puppetlabs/puppet/puppet.conf' }

    it 'should enable report handlers' do
      expect(subject).to contain_ini_setting('update report handlers').with({
        :ensure => 'present',
        :path => path,
        :section => 'master',
        :setting => 'reports',
        :value => 'console,puppetdb,irc,datadog_reports',
      })
    end

    it 'should enable pluginsync on the master' do
      expect(subject).to contain_ini_setting('enable master pluginsync').with({
        :ensure => 'present',
        :path => path,
        :section => 'master',
        :setting => 'pluginsync',
        :value => true,
      })
    end
  end

  it { should contain_file('/etc/puppetlabs/puppet/hiera.yaml') }
  it { should contain_firewall('010 allow dashboard traffic').with_action('accept').with_dport(443) }
  it { should contain_firewall('012 allow puppet agents').with_action('accept').with_dport(8140) }
  it { should contain_firewall('013 allow mcollective').with_action('accept').with_dport(61613) }

  context 'setting up the irc reporter' do
    it { should contain_class 'irc' }
  end

  context 'the datadog_agent module' do
    it { should contain_class 'datadog_agent' }

    context 'puppet reporting' do
      # Needed for reporting Puppet run reports to datadog
      it { should contain_package 'dogapi' }

      it { should contain_file('/etc/dd-agent/datadog.yaml') }
    end
  end

  it { should contain_package 'deep_merge' }
end
