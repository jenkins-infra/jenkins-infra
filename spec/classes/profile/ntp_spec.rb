require 'spec_helper'

describe 'profile::ntp' do
  it { should contain_class 'ntp' }
end
