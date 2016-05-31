require 'spec_helper'

describe 'profile::usage' do
  it { should contain_class 'profile::usage' }

  context 'apache setup' do
    let(:params) do
      {
        :docroot => '/tmp/rspec-docroot',
      }
    end

    it { should contain_class 'apache' }
    it { should contain_class 'profile::apachemisc' }
    it { should contain_class 'profile::firewall' }

    it 'should contain File[$docroot]' do
      expect(subject).to contain_file(params[:docroot]).with({
        :ensure => :directory,
        :require => 'Package[httpd]',
      })
    end

    it 'should contain File[usage-stats.js]' do
      expect(subject).to contain_file('usage-stats.js').with({
        :ensure => :file,
        :path => "#{params[:docroot]}/usage-stats.js",
        :require => "File[#{params[:docroot]}]",
      })
    end


    it 'should contain a logging directory' do
      expect(subject).to contain_file('/var/log/apache2/usage.jenkins.io').with({
        :ensure => :directory,
      })
    end

    it 'usage.jenkins.io vhost' do
      expect(subject).to contain_apache__vhost('usage.jenkins.io').with({
        :port => 443,
        :ssl => true,
        :docroot => params[:docroot],
        :options => 'Indexes FollowSymLinks MultiViews',
        :override => ['All'],
      })
    end

    it 'usage.jenkins.io unsecured vhost' do
      expect(subject).to contain_apache__vhost('usage.jenkins.io unsecured').with({
        :port => 80,
        :ssl => false,
        :docroot => params[:docroot],
        :options => 'Indexes FollowSymLinks MultiViews',
        :override => ['All'],
      })
    end
  end
end

