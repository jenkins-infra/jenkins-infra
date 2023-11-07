require 'spec_helper'

describe 'profile::accounts' do
  it { expect(subject).to contain_account 'tyler' }
  it { expect(subject).to contain_account 'kohsuke' }
  it { expect(subject).to contain_account 'dduportal' }
  it { expect(subject).to contain_account 'smerle' }
  it { expect(subject).to contain_account 'hlemeur' }
  it { expect(subject).to contain_account 'timja' }
end
