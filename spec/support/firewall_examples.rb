require 'rspec'

shared_examples 'it has webserver firewall rules' do
    it { expect(subject).to contain_firewall('200 allow http').with_action('accept').with_dport(80) }
    it { expect(subject).to contain_firewall('201 allow https').with_action('accept').with_dport(443) }
end
