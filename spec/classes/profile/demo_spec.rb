require 'spec_helper'

describe 'profile::demo' do
  it { should contain_class 'docker' }
  it { should contain_user 'demo' }
  it { should contain_docker__image 'jenkinsci/jenkins:2.0-alpha-2' }
  it { should contain_docker__run 'demo' }

  it { should contain_service('docker-demo') }
end
