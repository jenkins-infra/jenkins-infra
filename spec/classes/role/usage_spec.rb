require 'spec_helper'

describe 'role::usage' do
  it { should contain_class 'role::usage' }
  it { should contain_class 'profile::base' }
  it { should contain_class 'profile::usage' }
end
