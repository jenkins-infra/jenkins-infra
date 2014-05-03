require 'spec_helper'

describe 'profile::robobutler' do
  it { should contain_class 'docker' }
  it { should contain_user 'butlerbot' }
  it { should contain_file '/var/www/meetings.jenkins-ci.org'}
  it { should contain_file '/etc/butlerbot/main.conf' }

  it { should contain_docker__image 'jenkinsciinfra/butlerbot' }
  it { should contain_docker__run 'butlerbot' }
end
