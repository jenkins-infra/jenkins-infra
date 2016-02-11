require 'spec_helper'

describe 'role::cucumber' do
  it { should_not contain_class 'profile::base' }
  it { should contain_class 'profile::ldap' }
  it { should contain_class 'profile::diagnostics' }
end
