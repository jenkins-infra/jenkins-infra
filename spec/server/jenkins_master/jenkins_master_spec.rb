require_relative './../spec_helper'

describe 'jenkins_master' do
  it_behaves_like "a standard Linux machine"

  context 'the jenkins service' do
    describe service('jenkins') do
      it { should be_enabled }
      it { should be_running }
    end

    describe port(8080) do
      it { should be_listening }
    end
  end

  context 'apache' do
    describe service('apache2') do
      it { should be_enabled }
      it { should be_running }
    end

    describe port(80) do
      it { should be_listening }
    end

    describe port(443) do
      it { should be_listening }
    end

    context 'Blocking bots' do
      ['YisouSpider',
       'Catlight/1.8.7',
       'CheckmanJenkins (Hostname: derptown)',
      ].each do |agent|
        describe command("curl --verbose --insecure -A \"#{agent}\" -H 'Location: https://ci.jenkins.io/' --output /dev/null https://127.0.0.1/ 2>&1 | grep '403 Forbidden'") do
          its(:exit_status) { should eql 0 }
        end
      end
    end
  end
end
