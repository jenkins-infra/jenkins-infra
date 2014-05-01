require 'spec_helper'

describe 'role::spinach' do
  let(:pre_condition) do
    ['class profile::base { }']
  end

  it { should compile }
end
