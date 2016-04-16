require 'spec_helper'

describe 'role::jenkins::master' do
  it { should contain_class 'profile::base' }
  it { should contain_class 'profile::diagnostics' }
  it { should contain_class 'profile::buildmaster' }
  it { should contain_class 'jenkins' }
  it { should contain_class 'firewall' }
end

describe 'role::jenkins::agent' do
  it { should contain_class 'profile::base' }
  it { should contain_class 'profile::buildslave' }
end
