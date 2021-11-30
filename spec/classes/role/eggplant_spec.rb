require 'spec_helper'

describe 'role::eggplant' do
  it_should_behave_like 'a standard role'

  it { should contain_class 'profile::apachemisc' }
  it { should contain_class 'profile::sudo::osu' }
end
