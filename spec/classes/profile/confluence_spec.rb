require 'spec_helper'

describe 'profile::confluence' do
  it { should contain_class 'docker' }
  it { should contain_file '/srv/wiki/home' }
  it { should contain_service('docker-confluence') }

  it { should contain_firewall('400 allow http').with_action('accept').with_port(80) }
  it { should contain_firewall('401 allow https').with_action('accept').with_port(443) }
end
