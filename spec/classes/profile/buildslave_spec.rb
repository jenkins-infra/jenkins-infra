require 'spec_helper'

describe 'profile::buildslave' do
  it { should contain_file '/home/jenkins/.ssh' }
  it { should contain_user 'jenkins' }
end
