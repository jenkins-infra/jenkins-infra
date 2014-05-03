require 'spec_helper'

describe 'profile::docker' do
  it { should contain_class 'docker' }
end
