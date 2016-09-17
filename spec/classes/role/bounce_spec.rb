require 'spec_helper'

describe 'role::bounce' do
  let(:facts) do
    {
      :hiera_role => 'bounce',
    }
  end

  it { should contain_class 'role::bounce' }
  it { should contain_class 'profile::base' }

  # https://issues.jenkins-ci.org/browse/INFRA-909
  it { should contain_user 'ogondza' }
end
