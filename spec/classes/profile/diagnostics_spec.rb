require 'spec_helper'

describe 'profile::diagnostics' do
  it { should contain_package 'htop' }
  it { should contain_package 'strace' }

  it { should contain_class 'datadog_agent' }
end
