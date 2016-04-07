require 'spec_helper'

describe 'profile::r10k' do
  context 'r10k.yaml' do
    it { should contain_file('/etc/puppetlabs/r10k/r10k.yaml') }
  end
end
