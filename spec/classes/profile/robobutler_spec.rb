require 'spec_helper'

describe 'profile::robobutler' do
  it { expect(subject).to contain_class 'docker' }
  it { expect(subject).to contain_user 'butlerbot' }
  it { expect(subject).to contain_file '/var/www/meetings.jenkins-ci.org'}
  it { expect(subject).to contain_file '/etc/butlerbot/main.conf' }

  it { expect(subject).to contain_docker__image 'jenkinsciinfra/butlerbot' }
  it { expect(subject).to contain_docker__run 'butlerbot' }

  it { expect(subject).to contain_apache__vhost('meetings.jenkins-ci.org') }

  it_behaves_like 'it has webserver firewall rules'
end
