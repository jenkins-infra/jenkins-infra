require 'spec_helper'

describe 'profile::base' do
  it { should contain_class 'profile::accounts' }
  it { should contain_class 'profile::ntp' }
  it { should contain_class 'profile::sudo' }
end
