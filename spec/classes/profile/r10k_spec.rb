require 'spec_helper'

describe 'profile::r10k' do
  context 'r10k.yaml' do
    it { expect(subject).to contain_file('/etc/puppetlabs/r10k/r10k.yaml') }
  end

  context 'r10k webhook' do
    it 'should configure r10k::webhook::config' do
      expect(subject).to contain_class('r10k::webhook::config').with({
        :enable_ssl => false,
        :protected => false,
        :use_mcollective => false,
        :github_secret => 'justapassword',
      })
    end

    it 'should set up the webhook itself' do
      expect(subject).to contain_class('r10k::webhook').with({
        :use_mcollective => false,
        :user => 'root',
      })
    end

    it 'should open iptables for the webhook' do
      expect(subject).to contain_firewall('011 allow r10k webhooks').with({
        :dport => 8088,
        :action => :accept,
      })
    end
  end
end
