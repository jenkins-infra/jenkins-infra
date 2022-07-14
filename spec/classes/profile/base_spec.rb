require 'spec_helper'

describe 'profile::base' do
  shared_examples 'a cross platform base' do
    it { expect(subject).to contain_class 'profile::accounts' }
  end

  context 'on Linux' do
    it_behaves_like 'a cross platform base'
    it { expect(subject).to contain_class 'apt' }
    it { expect(subject).to contain_class 'profile::firewall' }
    it { expect(subject).to contain_class 'profile::ntp' }
    it { expect(subject).to contain_class 'profile::sudo' }
    it { expect(subject).to contain_class 'profile::diagnostics' }
    it { expect(subject).to contain_class 'profile::rngd' }

    context 'basic ssh configuration' do
      it { expect(subject).to contain_class 'ssh::server' }
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
    it { should_not contain_class 'apt' }
    it { should_not contain_class 'profile::ntp' }
    it { should_not contain_class 'profile::sudo' }
    it { should_not contain_class 'profile::diagnostics' }
  end
end
