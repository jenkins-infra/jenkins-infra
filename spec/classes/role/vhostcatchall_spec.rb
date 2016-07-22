require 'spec_helper'

describe 'role::vhostcatchall' do
  it { should contain_class 'role::vhostcatchall' }
  it { should contain_class 'profile::base' }
  it { should contain_class 'profile::catchall' }
end
