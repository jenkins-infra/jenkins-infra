require 'spec_helper'

describe 'profile::confluence' do
  it_behaves_like 'it has webserver firewall rules'

  it { should contain_class 'profile::atlassian' }
  it { should contain_class 'docker' }
  it { should contain_file '/srv/wiki/home' }
  it { should contain_service('docker-confluence') }

  context 'datadog configuration' do
    it { should contain_file '/etc/dd-agent/conf.d/http_check.yaml' }
    #it { should contain_file '/etc/dd-agent/conf.d/process_check.yaml' }
  end
end
