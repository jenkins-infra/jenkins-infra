require 'spec_helper'

describe 'profile::apache_misc' do
  it { should contain_file '/etc/apache2/conf.d/other-vhosts-access-log' }
end
