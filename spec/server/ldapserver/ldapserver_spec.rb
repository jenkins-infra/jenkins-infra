require_relative './../spec_helper'

describe 'ldapserver' do
  it_behaves_like "a standard Linux machine"

  context 'ldap' do
    describe service('slapd') do
      it { should be_enabled }
      it { should be_running }
    end

    describe port(389) do
      it { should be_listening }
    end

    describe port(636) do
      it { should be_listening }
    end
  end
end
