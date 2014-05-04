require 'spec_helper'

describe 'role::edamame' do
  it { should contain_class 'profile::base' }
  it { should contain_class 'profile::robobutler' }
  it { should contain_class 'profile::sudo::osu' }
end
