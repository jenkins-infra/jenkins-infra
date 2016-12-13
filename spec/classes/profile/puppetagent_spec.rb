require 'spec_helper'
describe 'profile::puppetagent' do
    it { should contain_class 'profile::puppetagent' }
    it { should contain_file ('/etc/dd-agent/conf.d/process_check.yaml') }
end
