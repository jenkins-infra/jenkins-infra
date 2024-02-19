require 'spec_helper'

describe 'profile::azcopy' do

  it { is_expected.to contain_exec('Install azcopy') }
  it { is_expected.to contain_package('curl') }
  it { is_expected.to contain_package('tar') }
end
