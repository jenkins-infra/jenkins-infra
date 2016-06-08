require 'spec_helper'

describe 'role::census' do
  it_should_behave_like 'a standard role'

  it { should contain_class 'profile::census' }
end


describe 'role::census::agent' do
  it_should_behave_like 'a standard role'
  it { should contain_class 'role::census::agent' }
  it { should contain_class 'role::jenkins::agent' }
end
