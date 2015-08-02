require 'spec_helper'

describe 'profile::atlassian' do
  it { should contain_class 'sudo' }
  it { should contain_class 'docker' }

  context 'provide Apache/mod_proxy support' do
    it { should contain_apache__mod 'proxy' }
    it { should contain_apache__mod 'proxy_http' }
  end

  context 'atlassian sudo specifics' do
    it { should contain_sudo__conf 'atlassian-admins' }
  end

end
