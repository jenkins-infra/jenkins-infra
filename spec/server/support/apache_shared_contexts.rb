require 'rspec'

shared_examples 'an Apache webserver' do
  describe service('apache2') do
    it { should be_enabled }
    it { should be_running }
  end

  describe iptables do
    it 'should have port 80 open' do
      should have_rule
          '-A INPUT -p tcp -m multiport --ports 80 -m comment --comment "200 allow http" -j ACCEPT'
    end

    it 'should have port 443 open' do
      should have_rule
        '-A INPUT -p tcp -m multiport --ports 443 -m comment --comment "201 allow https" -j ACCEPT'
    end
  end
end

shared_examples 'a static site host' do
  it_behaves_like 'an Apache webserver'

  describe file('/srv/jenkins.io') do
    it { should exist }
    it { should be_directory }
  end

  describe file('/srv/jenkins.io/archives') do
    it { should be_directory }
  end

  describe file('/srv/jenkins.io/current') do
    it { should be_symlink }
  end
end
