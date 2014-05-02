require 'spec_helper'

describe 'profile::vagrant' do
  it { should contain_sudo__conf 'ubuntu' }
end
