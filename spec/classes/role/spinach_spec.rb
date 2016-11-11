require 'spec_helper'

describe 'role::spinach' do
  it_should_behave_like 'a standard role'
  it { should contain_class 'profile::groovy' }
end
