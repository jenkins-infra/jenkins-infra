require 'spec_helper'

describe 'profile::bind' do
  it { should contain_class 'firewall' }
  it { should contain_service 'docker-bind' }

  it { should contain_docker__image 'jenkinsciinfra/bind' }

  it { should contain_file('/etc/bind/local/jenkins-ci.org.zone') }
  it { should contain_file('/etc/bind/local/named.conf.local') }
end
