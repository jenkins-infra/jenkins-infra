require 'rspec'


shared_examples 'a standard role' do
  it { expect(subject).to contain_class 'profile::base' }
  it { expect(subject).to contain_class 'profile::firewall' }
end
