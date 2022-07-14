require 'spec_helper'

describe 'profile::rngd' do
  it { expect(subject).to contain_package 'rng-tools' }
end
