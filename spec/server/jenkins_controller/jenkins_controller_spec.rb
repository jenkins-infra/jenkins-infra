require_relative './../spec_helper'

describe 'jenkins_controller' do
  it_behaves_like 'a standard Linux machine'
  it_behaves_like 'an Apache webserver'

  context 'the jenkins service' do
    describe service('docker-jenkins') do
      it { expect(subject).to be_enabled }
      it { expect(subject).to be_running }
    end

    describe port(8080) do
      it { expect(subject).to be_listening }
    end
  end

  context 'apache' do
    describe service('apache2') do
      it { expect(subject).to be_enabled }
      it { expect(subject).to be_running }
    end

    describe port(80) do
      it { expect(subject).to be_listening }
    end

    describe port(443) do
      it { expect(subject).to be_listening }
    end

    context 'HTTP redirects' do
      describe command("curl -kvH 'Host: ci.jenkins-ci.org' http://127.0.0.1") do
      its(:stderr) { should match 'Location: https://ci.jenkins.io/' }
      its(:exit_status) { should eq 0 }
      end
    end

    context 'Blocking bots' do
      # Bots are being redirected, booyah
      ['YisouSpider',
       'Catlight/1.8.7',
       'CheckmanJenkins (Hostname: derptown)',
      ].each do |agent|
        describe command("curl --verbose --insecure -A \"#{agent}\" -H 'Location: https://ci.jenkins.io/' https://127.0.0.1/api/json") do
          its(:exit_status) { should eql 0 }
          its(:stdout) { should match '{}' }
        end
      end
      # Same trick but this time with api/python
      describe command("curl --verbose --insecure -H 'Location: https://ci.jenkins.io/' https://127.0.0.1/api/python") do
        its(:exit_status) { should eql 0 }
        its(:stdout) { should match '{}' }
      end
      # And one more time but with api/xml
      describe command("curl --verbose --insecure -H 'Location: https://ci.jenkins.io/' https://127.0.0.1/api/xml") do
        its(:exit_status) { should eql 0 }
        its(:stdout) { should include '<a href="https://jenkins.io/infra/ci-redirects/">' }
      end
      # TODO check that it passes if Basic authorization is passed
    end
  end
end
