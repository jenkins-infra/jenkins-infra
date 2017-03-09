require 'spec_helper'

describe 'profile::datadog_ssl_check' do
  it { should contain_class 'datadog_agent' }
  it { should contain_file 'ssl_check_expire_days.py' }
  it { should contain_file 'ssl_check_expire_days.yaml' }
end
