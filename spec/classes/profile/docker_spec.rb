require 'spec_helper'

describe 'profile::docker' do
  it { expect(subject).to contain_class 'docker' }
  it { expect(subject).to contain_class 'datadog_agent::integrations::docker_daemon' }
  it { expect(subject).to contain_firewall('010 allow inter-docker traffic').with_action('accept').with_iniface('docker0') }
  it { expect(subject).to contain_file('/etc/docker').with('ensure' => 'directory')}
  it { expect(subject).to contain_file('/etc/docker/daemon.json')}
  it { expect(subject).to contain_cron('docker-system-prune').with('command' => "bash -c 'date && docker system prune --volumes --force' >/var/log/docker-system-prune.log 2>&1")}
end
