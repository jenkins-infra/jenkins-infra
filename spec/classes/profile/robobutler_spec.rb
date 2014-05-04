require 'spec_helper'

describe 'profile::robobutler' do
  it { should contain_class 'docker' }
  it { should contain_user 'butlerbot' }
  it { should contain_file '/var/www/meetings.jenkins-ci.org'}
  it { should contain_file '/etc/butlerbot/main.conf' }

  it { should contain_docker__image 'jenkinsciinfra/butlerbot' }
  it { should contain_docker__run 'butlerbot' }

  it 'should restart butlerbot when the docker conf updates' do
    should contain_file('/etc/init/docker-butlerbot.conf').that_notifies('Exec[restart-butlerbot]')
  end

  it { should contain_apache__vhost('meetings.jenkins-ci.org') }
end
