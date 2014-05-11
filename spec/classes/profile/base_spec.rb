require 'spec_helper'

describe 'profile::base' do
  it { should contain_class 'profile::accounts' }
  it { should contain_class 'profile::ntp' }
  it { should contain_class 'profile::sudo' }

  context 'in order to clean up after infra-puppet' do
    it { should contain_cron('pull puppet updates').with_ensure('absent') }
    it { should contain_cron('clean up old puppet logs').with_ensure('absent') }
    it { should contain_file('/root/infra-puppet').with_ensure('absent') }
    it { should contain_cron('clean the repo-update cache').with_ensure('absent') }
  end
end
