
require 'spec_helper'

describe 'profile::kubernetes::resources::evergreen' do
    it { should contain_class 'profile::kubernetes::kubectl' }
    it { should contain_class 'profile::kubernetes::resources::nginx' }
    it { should contain_class 'profile::kubernetes::resources::lego' }
end
