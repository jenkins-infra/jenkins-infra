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
