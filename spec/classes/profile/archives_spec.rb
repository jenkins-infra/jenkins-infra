require 'spec_helper'
require 'pry'

describe 'profile::archives' do
  let(:facts) {
    {:operatingsystem => 'Ubuntu', :osfamily => 'Debian' }
  }

  it { expect(subject).to contain_user('mirrorsync').with(
    :ensure     => 'present',
    :shell      => '/bin/bash',
    :managehome => 'true'
  )}

  it { expect(subject).to contain_file('/home/mirrorsync/.ssh').with(
    :ensure => 'directory',
    :mode   => '0700',
    :owner  => 'mirrorsync',
    :group  => 'mirrorsync',
  )}

  it { expect(subject).to contain_file('/var/log/mirrorsync').with(
    :ensure => 'directory',
    :mode   => '0770',
    :owner  => 'mirrorsync',
    :group  => 'mirrorsync',
  )}

  it { expect(subject).to contain_class 'profile::apachemisc' }
  it { expect(subject).to contain_class 'apache' }

  it_behaves_like 'it has webserver firewall rules'

  it { expect(subject).to contain_package('httpd').with(:name => 'apache2') }

  it { expect(subject).to contain_apache__mod 'bw' }
  it { expect(subject).to contain_apache__vhost 'archives.jenkins-ci.org' }

  it { expect(subject).to contain_package('rsync') }
  it { expect(subject).to contain_service('rsync').with(:ensure => 'running') }
  it { expect(subject).to contain_file('/etc/rsyncd.conf').with(
    :ensure => 'file',
    :owner  => 'root',
    :mode   => '0600')}
end
