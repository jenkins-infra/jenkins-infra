require 'spec_helper'

describe 'profile::base' do
  shared_examples 'a cross platform base' do
    it { should contain_class 'profile::accounts' }
    it { should contain_class 'profile::compliance' }
  end

  context 'on Linux' do
    it_behaves_like 'a cross platform base'
    it { should contain_class 'profile::apt' }
    it { should contain_class 'profile::firewall' }
    it { should contain_class 'profile::ntp' }
    it { should contain_class 'profile::sudo' }
    it { should contain_class 'profile::diagnostics' }

    context 'basic ssh configuration' do
      it { should contain_class 'ssh::server' }
    end
  end

  context 'on Darwin' do
    let(:facts) do
      {
        :kernel => 'Darwin',
      }
    end

    it_behaves_like 'a cross platform base'

    it { should_not contain_class 'profile::firewall' }
    it { should_not contain_class 'profile::apt' }
    it { should_not contain_class 'profile::ntp' }
    it { should_not contain_class 'profile::sudo' }
    it { should_not contain_class 'profile::diagnostics' }
  end
end
