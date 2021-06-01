require 'spec_helper'
require 'pry'

describe 'profile::archives' do
  let(:facts) {
    {:operatingsystem => 'Ubuntu', :osfamily => 'Debian' }
  }

  it { should contain_class 'profile::apachemisc' }
  it { should contain_class 'apache' }

  it_behaves_like 'it has webserver firewall rules'

  it { should contain_package('httpd').with(:name => 'apache2') }

  it { should contain_apache__mod 'bw' }
  it { should contain_apache__vhost 'archives.jenkins-ci.org' }

  it { should contain_package('rsync') }
  it { should contain_service('rsync').with(:ensure => 'running') }
  it { should contain_file('/etc/rsyncd.conf').with(
    :ensure => 'present',
    :owner  => 'root',
    :mode   => '0600')}
end
