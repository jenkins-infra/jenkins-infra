require 'spec_helper'

describe 'role::lettuce' do
  it_should_behave_like 'a standard role'

  it { should contain_class 'profile::sudo::osu' }
end
