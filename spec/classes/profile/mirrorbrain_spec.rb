require 'spec_helper'

describe 'profile::mirrorbrain' do
  it { should contain_class 'profile::firewall' }
  it { should contain_class 'mirrorbrain' }
  it { should contain_class 'mirrorbrain::apache' }
end
