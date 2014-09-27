require 'spec_helper'

describe 'profile::jenkinsadmin' do
  it { should contain_class 'docker' }
  it { should contain_user 'ircbot' }
  it { should contain_docker__image 'jenkinsciinfra/ircbot' }
  it { should contain_docker__run 'ircbot' }

  it { should contain_service('docker-ircbot') }

  context 'the configuration files' do
    it { should contain_file '/home/ircbot/.github' }
    it { should contain_file '/home/ircbot/.jenkins-ci.org' }
  end
end
