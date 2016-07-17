require 'spec_helper'

describe 'profile::letsencrypt' do
  it { should contain_class 'letsencrypt' }

  it 'should use a staging host for letsencrypt' do
    expect(subject).to contain_class('letsencrypt').with({
        :config => {
          "email" => 'tyler@monkeypox.org',
          "server" => "https://acme-staging.api.letsencrypt.org/directory",
        },
    })
  end

  # https://issues.jenkins-ci.org/browse/INFRA-812
  it 'should create a cron for updating domains and apache certs' do
    expect(subject).to contain_cron('letsencrypt-renew-reload').with({
      :user => 'root',
      :command => '/opt/letsencrypt/letsencrypt-auto renew --renew-hook="service apache2 reload"',
      :hour => 12,
    })
  end
end
