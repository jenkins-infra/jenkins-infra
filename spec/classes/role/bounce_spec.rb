require 'spec_helper'

describe 'role::bounce' do
  let(:facts) do
    {
      :clientcert => 'bounce',
    }
  end

  it { expect(subject).to contain_class 'role::bounce' }
  it { expect(subject).to contain_class 'profile::base' }
end
