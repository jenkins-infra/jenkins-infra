require_relative './../spec_helper'

describe 'openvpn' do
  it_behaves_like "a standard Linux machine"

  context 'openvpn' do
    describe service('docker') do
      it { should be_enabled }
      it { should be_running }
    end

    describe service('docker-openvpn') do
      it { should be_enabled }
      it { should be_running }
    end

    describe port(443) do
      it { should be_listening }
    end
  end
end
