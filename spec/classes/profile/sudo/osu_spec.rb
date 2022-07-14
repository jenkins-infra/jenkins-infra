require 'spec_helper'

describe 'profile::sudo::osu' do
  it { expect(subject).to contain_class 'profile::sudo' }

  it { expect(subject).to contain_sudo__conf 'osuadmin' }
end
