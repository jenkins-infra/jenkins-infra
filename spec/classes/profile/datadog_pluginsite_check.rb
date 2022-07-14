require 'spec_helper'

describe 'profile::datadog_pluginsite_check' do
  it { expect(subject).to contain_class 'datadog_agent' }
  it { expect(subject).to contain_file 'plugins_api_check.py' }
  it { expect(subject).to contain_file 'plugins_api_check.yaml' }
end
