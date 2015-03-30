require 'spec_helper'

describe 'profile::jira' do
  it { should contain_class 'docker' }
  it { should contain_file '/srv/jira/home' }
  it { should contain_service('docker-jira') }
end
