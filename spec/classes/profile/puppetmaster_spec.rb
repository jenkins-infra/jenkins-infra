require 'spec_helper'

describe 'profile::puppetmaster' do
  let(:pre_condition) do
    # Define our jenkins_keys class in our catalog, since it's provided by a
    # private module
    ['class jenkins_keys { }']
  end

  it { should contain_file('/etc/puppetlabs/puppet/hiera.yaml') }
  it { should contain_class 'jenkins_keys' }
end
