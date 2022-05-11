require 'spec_helper'

describe 'profile::rngd' do
  it { should contain_class 'profile::rngd' }
  it { should contain_package 'rng-tools' }
end
