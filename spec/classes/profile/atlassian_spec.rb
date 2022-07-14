require 'spec_helper'

describe 'profile::atlassian' do
  it { expect(subject).to contain_class 'sudo' }
  it { expect(subject).to contain_class 'docker' }

  context 'atlassian sudo specifics' do
    it { expect(subject).to contain_sudo__conf 'atlassian-admins' }
  end

end
