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

  describe iptables do
    it 'should have port 53 (TCP) open' do
      should have_rule
        '-A INPUT -p tcp -m multiport --ports 53 -m comment --comment "900 accept tcp DNS queries" -j ACCEPT'
    end

    it 'should have port 53 (UDP) open' do
      should have_rule
        '-A INPUT -p udp -m multiport --ports 53 -m comment --comment "901 accept udp DNS queries" -j ACCEPT'
    end
  end
end
