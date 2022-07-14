require 'spec_helper'

describe 'profile::nolegacy' do
  it { expect(subject).to contain_cron('pull puppet updates').with_ensure('absent') }
  it { expect(subject).to contain_cron('clean up old puppet logs').with_ensure('absent') }
  it { expect(subject).to contain_file('/root/infra-puppet').with_ensure('absent') }
  it { expect(subject).to contain_cron('clean the repo-update cache').with_ensure('absent') }
end
