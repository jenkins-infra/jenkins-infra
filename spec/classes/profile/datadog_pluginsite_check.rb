require 'spec_helper'

describe 'profile::datadog_pluginsite_check' do
  it { should contain_class 'datadog_agent' }
  it { should contain_file 'plugins_api_check.py' }
  it { should contain_file 'plugins_api_check.yaml' }
end
