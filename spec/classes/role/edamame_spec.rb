require 'spec_helper'

describe 'role::edamame' do
  it_should_behave_like 'a standard role'

  it { should contain_class 'profile::robobutler' }
  it { should contain_class 'profile::sudo::osu' }
end
