require 'spec_helper'

describe 'profile::ntp' do
  it { expect(subject).to contain_class 'ntp' }
end
