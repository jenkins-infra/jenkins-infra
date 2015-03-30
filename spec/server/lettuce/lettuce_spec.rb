require_relative './../spec_helper'

describe 'lettuce' do
  it_behaves_like "an OSU hosted machine"

  context 'Confluence' do
    describe port(8009) do
      it { should be_listening }
    end

    # test out reverse proxy to JIRA
    # use '--insecure' flag to skip SSL certificate check, as test boxes won't have the real private key nor the certificate
    describe command("curl --insecure -L http://wiki.jenkins-ci.org/") do
      its(:stdout) { should match /Jenkins Wiki/ }
    end
    describe command("curl --insecure -L https://wiki.jenkins-ci.org/") do
      its(:stdout) { should match /Jenkins Wiki/ }
    end
    describe command("ls -la /var/log/apache2/wiki.jenkins-ci.org") do
      its(:stdout) { should match 'access.log.[0-9]{14}' }
    end
  end
end
