require 'spec_helper'

describe 'profile::puppetmaster' do
  it { pending; should contain_class 'r10k' }
  it { pending; should contain_file('/etc/puppetlabs/puppet/hiera.yaml') }
end
