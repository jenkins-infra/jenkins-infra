require 'spec_helper'

describe 'profile::atlassian' do
  it { should contain_class 'docker' }

  context 'provide Apache/mod_proxy support' do
    it { should contain_apache__mod 'proxy' }
    it { should contain_apache__mod 'proxy_http' }
  end

  it { should contain_group('atlassian-admins') }
end
