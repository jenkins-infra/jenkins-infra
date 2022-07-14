require 'spec_helper'

describe 'role::puppetmaster' do
  let(:pre_condition) do
    ['class jenkins_keys { }']
  end

  it_should_behave_like 'a standard role'

  it { expect(subject).to contain_class 'profile::puppetmaster' }
  it { expect(subject).to contain_class 'profile::sudo::osu' }
  it { expect(subject).to contain_class 'profile::datadog_http_check' }
  it { expect(subject).to contain_class 'profile::datadog_pluginsite_check' }
end
