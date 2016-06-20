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
end
