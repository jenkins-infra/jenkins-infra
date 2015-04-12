require 'spec_helper'

describe 'profile::puppetmaster' do
  let(:pre_condition) do
    # Define our jenkins_keys class in our catalog, since it's provided by a
    # private module
    ['class jenkins_keys { }']
  end

  it { should contain_file('/etc/puppetlabs/puppet/hiera.yaml') }
  it { should contain_class 'jenkins_keys' }
  it { should contain_class 'irc' }
  it { should contain_firewall('010 allow dashboard traffic').with_action('accept').with_port(443) }
  it { should contain_firewall('011 allow r10k webhooks').with_action('accept').with_port(9013) }
end
