require 'rspec'

shared_examples 'a Docker host' do
  describe service('docker') do
    it { should be_enabled }
    it { should be_running }
  end
end
