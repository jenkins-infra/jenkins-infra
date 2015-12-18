require 'spec_helper'

describe 'role::cucumber' do
  it { should_not contain_class 'profile::base' }
end
