require 'spec_helper'

describe 'role::jenkins::master' do
  it { should contain_class 'profile::base' }
end

describe 'role::jenkins::agent' do
  it { should contain_class 'profile::base' }
end
