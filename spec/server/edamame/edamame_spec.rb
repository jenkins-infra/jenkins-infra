require_relative './../spec_helper'

describe 'edamame' do
  it_behaves_like "an OSU hosted machine"

  context 'butlerbot configuration' do
    describe command('docker ps') do
      its(:stdout) { should match /butlerbot/ }
    end

    describe file('/var/log/upstart/docker-butlerbot.log') do
      it { should be_file }
    end
  end
end
