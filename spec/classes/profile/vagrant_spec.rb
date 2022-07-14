require 'spec_helper'

describe 'profile::vagrant' do
  it { expect(subject).to contain_sudo__conf 'vagrant' }
end
