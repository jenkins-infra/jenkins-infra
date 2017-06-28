require 'spec_helper'

describe 'profile::datadog_http_check' do
  it { should contain_class('datadog_agent') }
  it { should contain_class('datadog_agent::integrations::http_check') }
end
