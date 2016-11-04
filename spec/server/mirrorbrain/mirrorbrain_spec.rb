require_relative './../spec_helper'

describe 'mirrorbrain' do
  it_behaves_like "a standard Linux machine"

  describe service('apache2') do
    it { should be_enabled }
    it { should be_running }
  end

  describe port(80) do
    it { should be_listening }
  end

  describe package('mirrorbrain') do
    it { should be_installed }
  end

  describe file('/etc/apache2/mods-enabled/dbd.conf') do
    it { should be_symlink }
  end

  describe file('/etc/apache2/mods-enabled/geoip.conf') do
    it { should be_symlink }
  end

  context 'pkgrepo' do
    describe file('/srv/releases/jenkins') do
      it { should be_directory }
    end

    ['jenkins.io.key', 'jenkins-ci.org.key'].each do |key|
      ['debian', 'debian-stable'].each do |repo|
        describe file("/var/www/pkg.jenkins.io/#{repo}/#{key}") do
          it { should be_file }
        end
      end
    end
  end

  describe 'Redirects' do
    cmd = "curl -kvIH 'Host: pkg.jenkins.io' https://127.0.0.1"

    # We should redirect HTTPs requests to pkg.jenkins.io to Azure blob storage
    # see also: https://issues.jenkins-ci.org/browse/INFRA-964
    describe command("#{cmd}/debian/binary/jenkins_2.0_all.deb") do
      its(:stderr) { should match 'Location: https://jenkinsreleases.blob.core.windows.net/debian/jenkins_2.0_all.deb' }
      its(:exit_status) { should eq 0 }
    end

    # see also: https://issues.jenkins-ci.org/browse/INFRA-967
    describe command("#{cmd}/redhat/jenkins-2.0-1.1.noarch.rpm") do
      its(:stderr) { should match 'Location: https://jenkinsreleases.blob.core.windows.net/redhat/jenkins-2.0-1.1.noarch.rpm' }
      its(:exit_status) { should eq 0 }
    end

    describe command("#{cmd}/redhat/RPMS/noarch/jenkins-2.0-1.1.noarch.rpm") do
      its(:stderr) { should match 'Location: https://jenkinsreleases.blob.core.windows.net/redhat/jenkins-2.0-1.1.noarch.rpm' }
      its(:exit_status) { should eq 0 }
    end

    describe command("#{cmd}/opensuse/jenkins-2.0-1.2.noarch.rpm") do
      its(:stderr) { should match 'Location: https://jenkinsreleases.blob.core.windows.net/opensuse/jenkins-2.0-1.2.noarch.rpm' }
      its(:exit_status) { should eq 0 }
    end

    context 'over HTTP' do
      cmd = "curl -kvIH 'Host: pkg.jenkins.io' http://127.0.0.1"
      describe command("#{cmd}/opensuse/jenkins-2.0-1.2.noarch.rpm") do
        its(:stderr) { should match 'Location: http://mirrors.jenkins.io/opensuse/jenkins-2.0-1.2.noarch.rpm' }
        its(:exit_status) { should eq 0 }
      end
    end
  end
end
