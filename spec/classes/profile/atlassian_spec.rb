require 'spec_helper'

describe 'profile::atlassian' do
  it { should contain_class 'sudo' }
  it { should contain_class 'docker' }

  context 'atlassian sudo specifics' do
    it { should contain_sudo__conf 'atlassian-admins' }
  end

end
