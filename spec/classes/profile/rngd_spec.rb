require 'spec_helper'

describe 'profile::rngd' do
  it { should contain_class 'rng-tools' }
end
