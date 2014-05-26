require 'rspec'


shared_examples "a DNS server" do

  context 'bind configuration' do
    describe command('docker ps') do
      its(:stdout) { should match /bind/ }
    end

    describe file('/etc/bind/local/named.conf.local') do
      it { should be_file }
    end

    describe file('/etc/bind/local/jenkins-ci.org.zone') do
      it { should be_file }
    end
  end

  describe port(53) do
    it { should be_listening }
  end

end
