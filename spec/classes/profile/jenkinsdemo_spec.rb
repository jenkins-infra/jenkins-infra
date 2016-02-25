require 'spec_helper'

describe 'profile::jenkins2demo' do
  it { should contain_class 'docker' }
  it { should contain_user 'jenkins2' }
  it { should contain_docker__image 'jenkinsci/jenkins:2.0-alpha-1' }
  it { should contain_docker__run 'jenkins2demo' }

  it { should contain_service('docker-jenkins2demo') }
end
