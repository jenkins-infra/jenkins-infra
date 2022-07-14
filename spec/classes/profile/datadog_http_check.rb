require 'spec_helper'

describe 'profile::datadog_http_check' do
  it { expect(subject).to contain_class('datadog_agent') }
  it { expect(subject).to contain_class('datadog_agent::integrations::http_check') }
end
