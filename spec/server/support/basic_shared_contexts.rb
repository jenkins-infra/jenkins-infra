require 'rspec'

shared_examples "a standard Linux machine" do
  describe port(22) do
    it { should be_listening }
  end

  # Make sure all our usual users are in place
  %w(abayer tyler kohsuke).each do |username|
    describe user(username) do
      it { should exist }
      it { should have_home_directory "/home/#{username}" }
    end
  end

  describe file('/etc/sudoers.d') do
    it { should be_directory }
  end

  describe cron do
    # apt auto updating malarky
    it { should have_entry('20 2 * * * apt-get update') }
  end


  describe file('/etc/ssh/sshd_config') do
    it { should contain 'PasswordAuthentication no' }
  end

  describe file('/etc/ssh/ssh_config') do
    # https://issues.jenkins-ci.org/browse/INFRA-546
    it { should contain 'UseRoaming no' }
  end

  # We should always have the agent running
  describe service('datadog-agent') do
    it { should be_enabled }
    it { should be_running }
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


shared_examples "a Jenkins build slave" do
  describe user('jenkins') do
    it { should exist }
    it { should have_home_directory '/home/jenkins' }
  end

  describe file('/home/jenkins/.ssh/authorized_keys') do
    it { should be_file }
  end
end
