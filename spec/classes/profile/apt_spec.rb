require 'spec_helper'

describe 'profile::apt' do
  it { should contain_cron('update the apt cache') }
end
