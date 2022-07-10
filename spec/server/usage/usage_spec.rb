require_relative './../spec_helper'

describe 'usage' do
  it_behaves_like "a standard Linux machine"

  context 'Apache' do
    describe service('apache2') do
      it { expect(subject).to be_enabled }
      it { expect(subject).to be_running }
    end

    describe port(80) do
      it { expect(subject).to be_listening }
    end

    describe port(443) do
      it { expect(subject).to be_listening }
    end
  end

  context '/srv/usage' do
    describe file('/srv/usage/usage-stats') do
      it { expect(subject).to be_directory }
      it { expect(subject).to be_owned_by 'usagestats' }
    end

    describe file('/srv/usage/apache-logs') do
      it { expect(subject).to be_directory }
    end
  end

  describe file('/var/log/usage-stats') do
    it { expect(subject).to be_symlink }
  end

  describe file('/var/log/apache2/usage.jenkins.io') do
    it { expect(subject).to be_symlink }
  end

  describe file('/var/log/apache2/usage.jenkins-ci.org') do
    it { expect(subject).to be_symlink }
  end

  context '/var/www/usage.jenkins.io' do
    describe file('/var/www/usage.jenkins.io') do
      it { expect(subject).to be_directory }
      it { expect(subject).to be_owned_by 'www-data' }
    end

    describe file('/var/www/usage.jenkins.io/usage-stats.js') do
      it { expect(subject).to be_file }
      it { expect(subject).to be_owned_by 'www-data' }
    end
  end
end
