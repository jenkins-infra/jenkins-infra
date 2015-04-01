require 'spec_helper'

describe 'profile::confluence' do
  it { should contain_class 'docker' }
  it { should contain_file '/srv/wiki/home' }
  it { should contain_service('docker-confluence') }
end
