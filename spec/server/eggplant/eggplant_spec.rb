require_relative './../spec_helper'

describe 'eggplant' do
  it_behaves_like "an OSU hosted machine"
  it_behaves_like 'a static site host'
  it_behaves_like 'a Docker host'


  it_behaves_like 'an Apache webserver'

  describe 'Redirects' do
    cmd = "curl -kvH 'Host: jenkins-ci.org' https://127.0.0.1"

    describe command(cmd) do
      its(:stderr) { should match 'Location: https://jenkins.io/index.html' }
      its(:exit_status) { should eq 0 }
    end

    describe command("#{cmd}/redhat/jenkins.io.key") do
      its(:stderr) { should match 'Location: https://pkg.jenkins.io/redhat/jenkins.io.key' }
      its(:exit_status) { should eq 0 }
    end

    describe command("#{cmd}/jenkins-ci.org.key") do
      its(:stderr) { should match 'Location: https://pkg.jenkins.io/redhat/jenkins.io.key' }
      its(:exit_status) { should eq 0 }
    end

    describe command("#{cmd}/issue/2") do
      its(:stderr) { should match 'Location: https://issues.jenkins-ci.org/browse/JENKINS-2' }
      its(:exit_status) { should eq 0 }
    end

    describe command("#{cmd}/rate/rate.js") do
      its(:stderr) { should match 'Location: https://rating.jenkins.io/rate.js' }
      its(:exit_status) { should eq 0 }
    end
  end
end
