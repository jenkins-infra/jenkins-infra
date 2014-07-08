require 'spec_helper'

describe 'profile::archives' do
  it {
    should contain_filesystem('/dev/archives/releases')
    should contain_package('apache2')
  }
end
