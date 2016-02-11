require_relative './../spec_helper'

describe 'cucumber' do
  context 'LDAP' do
    describe port(389) do
      it { should be_listening }
    end

    describe port(636) do
      it { should be_listening }
    end

    describe service('slapd') do
      it { should be_enabled }
      it { should be_running }
    end
  end
end
