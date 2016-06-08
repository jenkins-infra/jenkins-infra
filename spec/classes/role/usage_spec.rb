require 'spec_helper'

describe 'role::usage' do
  it_should_behave_like 'a standard role'
  it { should contain_class 'role::usage' }
  it { should contain_class 'profile::base' }
  it { should contain_class 'profile::usage' }
end
