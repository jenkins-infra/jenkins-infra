require 'spec_helper'

describe 'profile::diagnostics' do
  it { expect(subject).to contain_package 'htop' }
  it { expect(subject).to contain_package 'strace' }

  it { expect(subject).to contain_class 'datadog_agent' }
end
