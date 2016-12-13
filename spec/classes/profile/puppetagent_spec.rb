require 'spec_helper'
describe 'profile::puppetagent' do
    it { should contain_class 'profile::puppetagent' }
    it { should contain_profile__datadog_check('puppetagent-process-check').with(
            'checker' => 'process',
            'source'  => 'puppet:///modules/profile/puppetagent/process_check.yaml',
    ) }
end
