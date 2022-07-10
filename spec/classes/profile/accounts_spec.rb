require 'spec_helper'

describe 'profile::accounts' do
  it { expect(subject).to contain_account 'tyler' }
  it { expect(subject).to contain_account 'kohsuke' }
  it { expect(subject).to contain_account 'abayer' }

  it { expect(subject).to contain_group('atlassian-admins') }
end
