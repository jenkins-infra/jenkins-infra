require 'spec_helper'

describe 'profile::jiraveg' do
  it { should contain_class 'java' }
  it { should contain_class 'jiraveg' }
end