require 'spec_helper'

describe 'profile::rating' do
  it { should contain_class 'docker' }
  it { should contain_docker__image 'jenkinsciinfra/rating' }
  it { should contain_docker__run 'rating' }

  it { should contain_service('docker-rating') }
end
