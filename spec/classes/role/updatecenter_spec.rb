require 'spec_helper'

describe 'role::updatecenter' do
  it { expect(subject).to contain_class 'role::jenkins::agent' }
  it { expect(subject).to contain_class 'profile::updatecenter' }
end
