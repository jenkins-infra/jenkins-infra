require 'spec_helper'

describe 'role::bounce' do
  let(:facts) do
    {
      :clientcert => 'bounce',
    }
  end

  it { expect(subject).to contain_class 'role::bounce' }
  it { expect(subject).to contain_class 'profile::base' }

  # https://issues.jenkins-ci.org/browse/INFRA-909
  it { expect(subject).to contain_user 'ogondza' }
end
