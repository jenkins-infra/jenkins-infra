require 'spec_helper'

describe 'profile::ldap' do
  it { should contain_package 'slapd' }
  it { should contain_service('slapd').with_ensure(:running) }

  context "slapd's configuration" do
    it 'should add a defaults file' do
      expect(subject).to contain_file('/etc/default/slapd').with({
        :notify => 'Service[slapd]',
      })
    end
  end
end
