require 'spec_helper'

describe 'profile::sudo::osu' do
  it { should contain_class 'profile::sudo' }

  it { should contain_sudo__conf 'osuadmin' }
end
