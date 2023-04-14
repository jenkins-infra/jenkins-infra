require 'spec_helper'


describe 'profile::apachemisc' do
  let(:facts) do
    {
      :rspec_hieradata_fixture => 'profile_apachemisc',
    }
  end

  shared_examples 'apachemisc' do
    it { expect(subject).to contain_class 'apache' }
    it { expect(subject).to contain_package 'apache2-utils' }

    it { expect(subject).to contain_file '/etc/apache2/conf.d/00-reverseproxy_combined' }
    it { expect(subject).to contain_file '/etc/apache2/conf.d/other-vhosts-access-log' }
  end

  context 'with no class parameters' do
    it_behaves_like 'apachemisc'

    it { should_not contain_file '/var/www/.ssh' }
  end

  context 'with SSH access enabled' do
    let(:params) do
      {
        :ssh_enabled => true,
      }
    end

    it_behaves_like 'apachemisc'
  end

  context 'provide Apache/mod_proxy support' do
    it { expect(subject).to contain_apache__mod 'proxy' }
    it { expect(subject).to contain_apache__mod 'proxy_http' }
  end

  it 'restrict SSL versions by default' do
    expect(subject).to contain_class('apache::mod::ssl').with({
      :ssl_protocol => ['all', '-SSLv3'],
    })
  end


  context 'mod_status support' do
    it { expect(subject).to contain_class 'apache::mod::status' }
    it { expect(subject).to contain_file '/somewhere/apache.d/conf.yaml' }
  end
end
