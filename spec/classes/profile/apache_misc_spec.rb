require 'spec_helper'


describe 'profile::apache-misc' do
  shared_examples 'apache-misc' do
    it { should contain_class 'apache' }
    it { should contain_class 'apachelogcompressor' }
    it { should contain_package 'apache2-utils' }

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

  end

  context 'provide Apache/mod_proxy support' do
    it { should contain_apache__mod 'proxy' }
    it { should contain_apache__mod 'proxy_http' }
  end
end
