require 'spec_helper'

describe 'role::edamame' do
  let(:pre_condition) do
    ['class profile::base { }']
  end

  it { should compile }
  it { should contain_class 'profile::sudo::osu' }
end
