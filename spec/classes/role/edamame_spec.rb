require 'spec_helper'

describe 'role::edamame' do
  it_should_behave_like 'a standard role'

  it { expect(subject).to contain_class 'profile::sudo::osu' }
end
