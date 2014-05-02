require 'spec_helper'

describe 'profile::bind' do
  it { should contain_service 'docker-bind' }
end
