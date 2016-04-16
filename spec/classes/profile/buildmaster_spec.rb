require 'spec_helper'

describe 'profile::buildmaster' do
  it { should contain_class 'jenkins' }

  context 'jenkins master configuration' do
    it 'should contain zero executors for security' do
      expect(subject).to contain_class('jenkins').with({
        :executors => 0,
      })
    end

    it 'should default to LTS' do
      expect(subject).to contain_class('jenkins').with({
        :lts => true,
      })
    end
  end
end
