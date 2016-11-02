require 'spec_helper'

describe 'role::okra' do
  it_should_behave_like 'a standard role'

  it { should contain_class 'profile::archives' }
  it { should contain_class 'profile::bind' }

  it { should contain_class 'profile::pluginsite' }
end
