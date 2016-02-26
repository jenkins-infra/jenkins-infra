require 'spec_helper'

describe 'profile::demo' do
  it { should contain_class 'docker' }
  it { should contain_user 'jenkins2' }
  it { should contain_docker__image 'jenkinsci/jenkins:2.0-alpha-1' }
  it { should contain_docker__run 'demo' }

  it { should contain_service('docker-demo') }
end
