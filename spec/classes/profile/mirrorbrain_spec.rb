require 'spec_helper'

describe 'profile::mirrorbrain' do
  let(:params) do
    {
      :pg_host => 'rspec',
      :pg_database => 'rspecdb',
      :pg_username => 'rspecuser',
      :pg_password => 'rspecpassword',
      :home_dir    => '/tmp/rspec-home',
      :user        => 'rspec',
      :group       => 'rspec',
    }
  end

  it { should contain_class 'profile::apachemisc' }
  it { should contain_class 'profile::firewall' }
  it { should contain_class 'profile::letsencrypt' }

  it { should contain_class 'mirrorbrain' }
  it { should contain_class 'mirrorbrain::apache' }

  context 'release files' do
    let(:file_properties) do
      {
        :ensure => :present,
        :owner  => params[:user],
        :group  => params[:group],
      }
    end


    [
      'rsync.filter',
      'sync.sh',
      'populate-archives.sh',
      'populate-fallback.sh',
      'update-latest-symlink.sh',
    ].each do |filename|
      it "should manage #{filename}" do
        expect(subject).to contain_file("#{params[:home_dir]}/#{filename}").with(file_properties)
      end
    end
  end


  it 'should ensure the $docroot is owned by $user' do
    expect(subject).to contain_file('/srv/releases/jenkins').with({
      :ensure => :directory,
      :owner  => params[:user],
      :group  => params[:group],
    })
  end


  context 'the mirrorbrain user' do
    it 'should have a valid shell' do
      expect(subject).to contain_user(params[:user]).with({
          :ensure => :present,
          :shell  => '/bin/bash',
      })
    end

    it 'should have a group' do
      expect(subject).to contain_group(params[:group]).with_ensure(:present)
    end

    it 'should have a home_dir' do
      expect(subject).to contain_account(params[:user]).with({
        :home_dir => params[:home_dir],
        :manage_home => true,
        :home_dir_perms => '0755',
      })
    end

    context 'with ssh_keys => []' do
      let(:params) do
        {
          :ssh_keys => {
            'kohsuke-griffon' => {
              'type' => 'ssh-rsa',
              'key' => 'kohsukeskey',
            }
          },
        }
      end

      it { should contain_ssh_authorized_key('mirrorbrain-kohsuke-griffon').with_key('kohsukeskey') }
    end

  end

  it 'should install mirrorbrain.conf' do
    expect(subject).to contain_file('/etc/mirrorbrain.conf').with({
      :ensure => :present,
      :owner   => params[:user],
      :group  => params[:group],
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
      :owner => params[:user],
      :group  => params[:group],
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
