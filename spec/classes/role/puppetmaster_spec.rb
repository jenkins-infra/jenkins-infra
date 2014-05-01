require 'spec_helper'

describe 'role::puppetmaster' do
  let(:pre_condition) do
    ['class jenkins_keys { }']
  end

  it { should contain_class 'profile::puppetmaster' }
  it { should contain_class 'profile::base' }
  it { should contain_class 'profile::sudo::osu' }
end
