require 'rspec'

shared_examples 'an Apache webserver' do
  describe service('apache2') do
    it { expect(subject).to be_enabled }
    it { expect(subject).to be_running }
  end

  describe iptables do
    it 'should have port 80 open' do
      should have_rule
          '-A INPUT -p tcp -m multiport --ports 80 -m comment --comment "200 allow http" -j ACCEPT'
    end
  end
end

shared_examples 'an Apache webserver with SSL' do
  it_behaves_like 'an Apache webserver'

  context 'ssl.conf' do
    describe file('/etc/apache2/conf.d/ssl.conf') do
      it { expect(subject).to be_file }
      its(:content) { should match /-SSLv2 -SSLv3/ }
    end
  end

  describe iptables do
    it 'should have port 443 open' do
      should have_rule
        '-A INPUT -p tcp -m multiport --ports 443 -m comment --comment "201 allow https" -j ACCEPT'
    end
  end
end

shared_examples 'a static site host' do
  it_behaves_like 'an Apache webserver'

  describe file('/srv/jenkins.io') do
    it { expect(subject).to exist }
    it { expect(subject).to be_directory }
  end

  describe file('/srv/jenkins.io/archives') do
    it { expect(subject).to be_directory }
  end

  describe file('/srv/jenkins.io/current') do
    it { expect(subject).to be_symlink }
  end
end
