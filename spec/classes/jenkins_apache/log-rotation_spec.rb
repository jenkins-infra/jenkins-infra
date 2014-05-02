require 'spec_helper'

describe 'jenkins_apache::log_rotation' do
  it { should contain_file '/var/log/apache2/compress-log.rb' }
end
