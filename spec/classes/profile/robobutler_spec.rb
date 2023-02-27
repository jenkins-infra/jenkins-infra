require 'spec_helper'

describe 'profile::robobutler' do
  it { expect(subject).to contain_class 'docker' }
  it { expect(subject).to contain_user 'butlerbot' }
  it { expect(subject).to contain_file '/etc/butlerbot/main.conf' }

  it { expect(subject).to contain_docker__image 'jenkinsciinfra/butlerbot' }
  it { expect(subject).to contain_docker__run 'butlerbot' }
end
