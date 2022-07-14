require 'spec_helper'

describe 'role::jenkins::controller' do
  it { should contain_class 'profile::base' }
  it { should contain_class 'profile::diagnostics' }
  it { should contain_class 'profile::jenkinscontroller' }
  it { should contain_class 'firewall' }
end

describe 'role::jenkins::agent' do
  it { should contain_class 'profile::base' }
  it { should contain_class 'profile::buildagent' }

  context 'on Mac OS X' do
    let(:facts) do
      {
        :kernel => 'Darwin',
      }
    end

    it 'should contain a modified buildagent profile' do
      expect(subject).to contain_class('profile::buildagent').with({
        :ruby => false,
        :docker => false,
      })
    end
  end
end
