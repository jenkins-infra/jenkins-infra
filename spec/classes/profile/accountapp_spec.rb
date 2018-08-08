require 'spec_helper'

describe 'profile::accountapp' do
  it { should contain_class 'profile::accountapp' }

  context 'letsencrypt setup' do
    let(:environment) { 'production' }
    let(:vagrant) { nil }

    it { should_not contain_letsencrypt__certonly('accounts.jenkins.io') }
    it { should contain_class 'Letsencrypt' }
  end
end
