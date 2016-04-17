require 'spec_helper'

describe 'profile::mirrorbrain' do
  it { should contain_class 'profile::apachemisc' }
  it { should contain_class 'profile::firewall' }
  it { should contain_class 'profile::letsencrypt' }

  it { should contain_class 'mirrorbrain' }
  it { should contain_class 'mirrorbrain::apache' }

  context 'apache setup' do
    it { should contain_apache__mod 'dbd' }

    it { should contain_package('libaprutil1-dbd-pgsql').with_ensure 'present' }
  end
end
