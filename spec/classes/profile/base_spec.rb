require 'spec_helper'

describe 'profile::base' do
  it { should contain_class 'profile::accounts' }
  it { should contain_class 'profile::ntp' }
  it { should contain_class 'profile::sudo' }
  it { should contain_class 'profile::apt' }
  it { should contain_class 'profile::firewall' }
  it { should contain_class 'profile::diagnostics' }

  context 'basic ssh configuration' do
    it { should contain_class 'ssh::server' }
  end
end
