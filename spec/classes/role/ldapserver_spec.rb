require 'spec_helper'

describe 'role::ldapserver' do
  it { should contain_class 'profile::base' }
  it { should contain_class 'profile::ldap' }
end
