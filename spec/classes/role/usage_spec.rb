require 'spec_helper'

describe 'role::usage' do
  it_should_behave_like 'a standard role'
  it { expect(subject).to contain_class 'role::usage' }
  it { expect(subject).to contain_class 'profile::base' }
  it { expect(subject).to contain_class 'profile::usage' }
end
