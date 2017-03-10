require 'spec_helper'

describe 'role::puppetmaster' do
  let(:pre_condition) do
    ['class jenkins_keys { }']
  end

  it_should_behave_like 'a standard role'

  it { should contain_class 'profile::puppetmaster' }
  it { should contain_class 'profile::sudo::osu' }
  it { should contain_class 'profile::datadog_ssl_check' }
end
