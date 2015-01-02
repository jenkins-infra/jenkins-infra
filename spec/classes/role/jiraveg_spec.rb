require 'spec_helper'

describe 'role::jiraveg' do
  it_should_behave_like 'a standard role'

  it { should contain_class 'profile::jiraveg' }
end
