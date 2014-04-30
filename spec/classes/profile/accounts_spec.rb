require 'spec_helper'

describe 'profile::accounts' do
  it { should contain_account 'tyler' }
  it { should contain_account 'kohsuke' }
  it { should contain_account 'abayer' }
end
