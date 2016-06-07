require 'spec_helper'

describe 'role::mirrorbrain' do
  it_should_behave_like 'a standard role'
  it { should contain_class 'profile::base' }
  it { should contain_class 'profile::mirrorbrain' }
  it { should contain_class 'profile::pkgrepo' }
  it { should contain_class 'profile::updatesite' }
end
