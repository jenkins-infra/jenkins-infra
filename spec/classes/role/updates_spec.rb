require 'spec_helper'

describe 'role::updates' do
  it_should_behave_like 'a standard role'
  it { expect(subject).to contain_class 'profile::base' }
  it { expect(subject).to contain_class 'profile::updatesite' }
  it { expect(subject).to contain_class 'lvm' }
  it { expect(subject).to contain_package 'lvm2' }
end
