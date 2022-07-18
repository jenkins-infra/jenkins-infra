require 'spec_helper'

describe 'role::updates' do
  it_should_behave_like 'a standard role'
  it { should contain_class 'profile::updatesite' }
end
