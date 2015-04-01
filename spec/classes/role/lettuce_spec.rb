require 'spec_helper'

describe 'role::lettuce' do
  it_should_behave_like 'a standard role'

  it { should contain_class 'profile::sudo::osu' }
  it { should contain_docker__run 'confluence' }
  it { should contain_service 'docker-confluence' }
  it { should contain_service 'docker-confluence-cache' }
end
