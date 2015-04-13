require 'spec_helper'

describe 'profile::apache-misc' do
  shared_examples 'apache-misc' do
    it { should contain_class 'apache' }
    it { should contain_class 'apache-logcompressor' }

    it { should contain_file '/etc/apache2/conf.d/00-reverseproxy_combined' }
    it { should contain_file '/etc/apache2/conf.d/other-vhosts-access-log' }
  end

  context 'with no class parameters' do
    it_behaves_like 'apache-misc'

    it { should_not contain_file '/var/www/.ssh' }
  end

  context 'with SSH access enabled' do
    let(:params) do
      {
        :ssh_enabled => true,
      }
    end

    it_behaves_like 'apache-misc'

    it { should contain_file '/var/www/.ssh' }
    it { should contain_file '/var/www/.ssh/authorized_keys' }

    it { should contain_firewall('200 allow http requests').with_action('accept').with_port(80) }
    it { should contain_firewall('201 allow https requests').with_action('accept').with_port(443) }
  end
end
