require 'spec_helper'

describe 'role::kubernetes' do
    it { should contain_class 'profile::kubernetes::resources::datadog'}
    it { should contain_class 'profile::kubernetes::resources::pluginsite'}
end
