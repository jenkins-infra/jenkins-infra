require 'spec_helper'
describe 'profile::puppetagent' do
    it { expect(subject).to contain_class 'profile::puppetagent' }
    it { expect(subject).to contain_profile__datadog_check('puppetagent-process-check').with(
            'checker' => 'process',
            'source'  => 'puppet:///modules/profile/puppetagent/process_check.yaml',
    ) }
end
