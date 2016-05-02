require 'spec_helper'

describe 'profile::census' do
  it { should contain_class 'profile::apachemisc' }
  it { should contain_class 'lvm' }
  it { should contain_class 'apache' }

  it_behaves_like 'it has webserver firewall rules'

  it { should contain_package('httpd').with(:name => 'apache2') }
  it { should contain_apache__vhost 'census.jenkins.io' }
end
