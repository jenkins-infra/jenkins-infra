require_relative './../spec_helper'

describe 'pkg' do
  it_behaves_like "a standard Linux machine"

  context 'pkg' do
    # This assertion fails (during provisioning) because of missing letsencrypt:
    # `SSLCertificateFile: file '/etc/letsencrypt/live/updates.jenkins-ci.org/cert.pem' does not exist or is empty`
    # We keep this test to allow "vagrant up pkg" to be executable (despite failing) so we can
    # at least check the generated configuration
    ## TODO: find a way to "mock" letsencrypt certificate

    describe service('apache2') do
      it { expect(subject).to be_enabled }
      it { expect(subject).to be_running }
    end
  end
end
