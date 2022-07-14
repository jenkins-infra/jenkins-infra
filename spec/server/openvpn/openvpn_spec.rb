require_relative './../spec_helper'

describe 'openvpn' do
  it_behaves_like "a standard Linux machine"

  context 'openvpn' do
    describe service('docker') do
      it { expect(subject).to be_enabled }
      it { expect(subject).to be_running }
    end

    describe service('docker-openvpn') do
      it { expect(subject).to be_enabled }
      it { expect(subject).to be_running }
    end

    describe port(443) do
      it { expect(subject).to be_listening }
    end
  end
end
