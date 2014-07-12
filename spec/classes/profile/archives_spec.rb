require 'spec_helper'
require 'pry'

describe 'profile::archives' do
  let(:facts) {
    {:operatingsystem => 'Ubuntu', :osfamily => 'Debian' }
  }

  it {
    should contain_filesystem('/dev/archives/releases')
    should contain_package('httpd').with( :name => 'apache2' )
  }
end
