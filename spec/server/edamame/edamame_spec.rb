require_relative './../spec_helper'

describe 'edamame' do
  it_behaves_like "an OSU hosted machine"
  it_behaves_like "a DNS server"
  it_behaves_like 'an Apache webserver with SSL'

  context 'butlerbot configuration' do
    describe command('docker ps') do
      its(:stdout) { should match /butlerbot/ }
    end

    describe file('/var/log/upstart/docker-butlerbot.log') do
      it { should be_file }
    end
  end

  context 'apache configuration' do
    describe file('/var/www/meetings.jenkins-ci.org') do
      it { should be_directory }
    end

    describe file('/etc/apache2/sites-enabled/25-meetings.jenkins-ci.org.conf') do
      it { should be_file }
      its(:content) { should match /CustomLog/ }
    end

    describe file('/usr/local/bin/apache-compress-log') do
      it { should be_file }
    end

    describe file('/etc/apache2/server.key') do
      it {
        should be_file
        should be_mode 600
      }
    end
  end

end
