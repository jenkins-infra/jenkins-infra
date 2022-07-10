require 'rspec'

shared_examples "a standard Linux machine" do
  describe port(22) do
    it { expect(subject).to be_listening }
  end

  # Make sure all our usual users are in place
  %w(abayer tyler kohsuke).each do |username|
    describe user(username) do
      it { expect(subject).to exist }
      it { expect(subject).to have_home_directory "/home/#{username}" }
    end
  end

  describe file('/etc/sudoers.d') do
    it { expect(subject).to be_directory }
  end

  describe cron do
    # apt auto updating malarky
    it { expect(subject).to have_entry('20 2 * * * apt-get update') }
  end


  describe file('/etc/ssh/sshd_config') do
    it { expect(subject).to contain 'PasswordAuthentication no' }
  end

  describe file('/etc/ssh/ssh_config') do
    # https://issues.jenkins-ci.org/browse/INFRA-546
    it { expect(subject).to contain 'UseRoaming no' }
  end

  # We should always have the agent running
  describe service('datadog-agent') do
    it { expect(subject).to be_enabled }
    it { expect(subject).to be_running }
  end
end

shared_examples "an OSU hosted machine" do
  it_behaves_like "a standard Linux machine"

  # Ensure that we have the sudoers file for `osuadmin`
  describe command('ls /etc/sudoers.d') do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match /osuadmin/ }
  end
end
