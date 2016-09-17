require 'spec_helper'

describe 'role::bounce' do
  it { should contain_class 'role::bounce' }
  it { should contain_class 'profile::base' }
end
