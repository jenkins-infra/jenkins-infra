require 'spec_helper'
require 'pry'

describe 'profile::archives' do
  let(:facts) {
    {:operatingsystem => 'Ubuntu', :osfamily => 'Debian' }
  }

  it { should contain_class 'profile::apache-misc' }
  it { should contain_class 'lvm' }
  it { should contain_class 'apache' }

  it { should contain_filesystem '/dev/archives/releases' }
  it { should contain_package('httpd').with(:name => 'apache2') }

  it { should contain_apache__mod 'bw' }
  it { should contain_apache__vhost 'archives.jenkins-ci.org' }
end
