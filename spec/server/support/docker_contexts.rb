require 'rspec'

shared_examples 'a Docker host' do
  describe service('docker') do
    it { expect(subject).to be_enabled }
    it { expect(subject).to be_running }
  end
end
