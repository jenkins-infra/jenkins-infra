require 'spec_helper'

describe 'role::jenkins::controller' do
  it { expect(subject).to contain_class 'profile::base' }
  it { expect(subject).to contain_class 'profile::diagnostics' }
  it { expect(subject).to contain_class 'profile::jenkinscontroller' }
  it { expect(subject).to contain_class 'firewall' }
end

describe 'role::jenkins::agent' do
  it { expect(subject).to contain_class 'profile::base' }
  it { expect(subject).to contain_class 'profile::buildagent' }
end
