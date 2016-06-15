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


  context 'postgresql configuration' do
    it { should contain_package('postgresql-server').with_ensure 'present' }

    it 'should create the mirrorbrain database' do
      expect(subject).to contain_postgresql__server__db(params[:pg_database]).with({
        :user => params[:pg_username],
        :password => params[:pg_password],
      })
    end

    context 'postgresql monitoring' do
      it { should contain_postgresql__server__role('datadog') }

      it 'should grant the `datadog` user read privileges on our db' do
        expect(subject).to contain_postgresql__server__grant("datadog_#{params[:pg_database]}").with({
          :role => 'datadog',
          :db => params[:pg_database],
          :privilege => 'SELECT',
          :object_type => 'ALL TABLES IN SCHEMA',
        })
      end

      it 'should monitor postgresql' do
        expect(subject).to contain_class('datadog_agent::integrations::postgres').with({
          :host => 'localhost',
          :dbname => params[:pg_database],
          :username => 'datadog',
        })
      end
    end


    context 'when the params include manage_pgsql => false' do
      let(:params) { {:manage_pgsql => false } }
      it { should_not contain_package('postgresql-server') }
    end
  end

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

    it 'should manage ssh client configuration' do
      expect(subject).to contain_ssh__client__config__user(params[:user])
    end

    it 'should provision the OSUOSL mirroring private key' do
      expect(subject).to contain_file('osuosl_mirror').with({
          :ensure => :present,
          :mode => '0600',
          :owner => params[:user],
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

  context 'crontabs' do
    it { should contain_cron 'mirrorbrain-time-update' }
    it { should contain_cron 'mirmon-status-page' }
    it { should contain_cron 'mirrorbrain-ping-mirrors' }
    it { should contain_cron 'mirrorbrain-scan' }
    it { should contain_cron 'mirrorbrain-db-cleanup' }
    it { should contain_cron 'mirmon-update-mirror-list' }

    it 'should install a `./sync.sh` crontab entry for `mirrorbrain`' do
      expect(subject).to contain_cron('mirrorbrain-sync-releases').with({
        :user => params[:user],
        :minute => '0',
      })
    end
  end
end
