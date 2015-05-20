require 'rspec'

shared_examples 'it has webserver firewall rules' do
    it { should contain_firewall('200 allow http').with_action('accept').with_port(80) }
    it { should contain_firewall('201 allow https').with_action('accept').with_port(443) }
end
