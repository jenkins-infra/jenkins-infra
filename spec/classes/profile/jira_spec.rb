require 'spec_helper'

describe 'profile::jira' do
  it_behaves_like 'it has webserver firewall rules'

  it { should contain_class 'profile::atlassian' }
  it { should contain_class 'docker' }
  it { should contain_file '/srv/jira/home' }
  it { should contain_service('docker-jira') }
  it { should contain_file '/var/www/maintenance/maintenance.html' }
  it { should contain_file '/etc/apache2/sites-available/issues.jenkins-ci.org.maintenance.conf' }
  it { should contain_file '/var/log/apache2/issues.jenkins.io' }
  it { should contain_apache__vhost 'issues.jenkins.io' }

  context 'datadog configuration' do
    it { should contain_file '/etc/datadog-agent/conf.d/process.yaml' }
  end
end
