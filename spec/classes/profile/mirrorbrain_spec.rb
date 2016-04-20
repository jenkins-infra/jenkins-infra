require 'spec_helper'

describe 'profile::mirrorbrain' do
  let(:params) do
    {
      :pg_host => 'rspec',
      :pg_database => 'rspecdb',
      :pg_username => 'rspecuser',
      :pg_password => 'rspecpassword',
    }
  end

  it { should contain_class 'profile::apachemisc' }
  it { should contain_class 'profile::firewall' }
  it { should contain_class 'profile::letsencrypt' }

  it { should contain_class 'mirrorbrain' }
  it { should contain_class 'mirrorbrain::apache' }

  it 'should ensure the mirrorbrain user has a valid shell' do
    expect(subject).to contain_user('mirrorbrain').with({
        :ensure => :present,
        :shell  => '/bin/bash',
    })
  end

  it 'should install mirrorbrain.conf' do
    expect(subject).to contain_file('/etc/mirrorbrain.conf').with({
      :ensure => :present,
      :owner   => 'mirrorbrain',
      :group  => 'mirrorbrain',
      :content => "[general]
instances = main

[main]
dbuser = rspecuser
dbpass = rspecpassword
dbdriver = postgresql
dbhost = rspec
dbname = rspecdb

[mirrorprobe]
# logfile = /var/log/mirrorbrain/mirrorprobe.log
# loglevel = INFO
",
    })
  end

  it 'should install mirmon.conf' do
    expect(subject).to contain_file('/etc/mirmon.conf').with({
      :ensure => :present,
      :owner => 'mirrorbrain',
      :group  => 'mirrorbrain',
    })
  end

  context 'apache setup' do
    it { should contain_apache__mod 'dbd' }

    it { should contain_package('libaprutil1-dbd-pgsql').with_ensure 'present' }

    context 'dbd configuration' do

      it 'should install the dbd.conf file' do
        configuration = <<-EOF
<IfModule mod_dbd.c>
    DBDriver pgsql
    DBDParams 'host=rspec user=rspecuser password=rspecpassword dbname=rspecdb connect_timeout=15'
</IfModule>
EOF
        expect(subject).to contain_file('/etc/apache2/mods-available/dbd.conf').with({
          :ensure => :present,
          :owner => 'root',
          :content => configuration,
        })
      end

      it 'should enable the dbd.conf by linking it in mods-enabled' do
        expect(subject).to contain_file('/etc/apache2/mods-enabled/dbd.conf').with({
          :ensure => :link,
          :target => '/etc/apache2/mods-available/dbd.conf',
        })
      end
    end

    context 'geoip configuration' do
      it 'should install the geoip.conf file' do
        expect(subject).to contain_file('/etc/apache2/mods-available/geoip.conf').with({
          :ensure => :present,
          :owner => 'root',
        })
      end

      it 'should enable the geoip.conf by linking it in mods-enabled' do
        expect(subject).to contain_file('/etc/apache2/mods-enabled/geoip.conf').with({
          :ensure => :link,
          :target => '/etc/apache2/mods-available/geoip.conf',
        })
      end
    end

    context 'vhost' do
      it { should contain_apache__vhost 'mirrors.jenkins.io' }
    end
  end
end
