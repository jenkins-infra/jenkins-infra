require 'spec_helper'

#files = [
#  '/etc/accountapp',
#  '/etc/letsencrypt/live/accounts.jenkins.io/privkey.pem',
#  '/etc/letsencrypt/live/accounts.jenkins.io/cert.pem',
#  '/etc/letsencrypt/live/accounts.jenkins.io/chain.pem',
#  ]
#
#vhosts = [
#  'accounts.jenkins.io',
#  'accounts.jenkins.io unsecured'
#  ]
#
#
#describe 'profile::accountapp' do
#  files.each do | file|
#    it { should contain_file(file).with_ensure(:absent) }
#  end
#  vhosts.each do | vhost|
#    it { should contain_apache__vhost(vhost).with_ensure(:absent)}
#  end
#  it { should contain_docker__run('account-app').with_ensure(:absent)}
#end
