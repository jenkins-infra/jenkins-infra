require 'spec_helper'

describe 'profile::jira' do
  it { should contain_class 'docker' }
  it { should contain_file '/srv/jira/home' }
  it { should contain_service('docker-jira') }
  it { should contain_file '/var/www/maintenance/maintenance.html' }
  it { should contain_file '/etc/apache2/sites-available/issues.jenkins-ci.org.maintenance' }
end
