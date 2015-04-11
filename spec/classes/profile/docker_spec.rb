require 'spec_helper'

describe 'profile::docker' do
  it { should contain_class 'docker' }
  it { should contain_firewall('010 allow inter-docker traffic').with_action('accept').with_iniface('docker0') }
end
