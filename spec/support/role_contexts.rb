require 'rspec'


shared_examples 'a standard role' do
  it { should contain_class 'profile::base' }
  it { should contain_class 'profile::firewall' }
end
