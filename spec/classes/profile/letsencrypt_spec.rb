require 'spec_helper'

describe 'profile::letsencrypt' do
  it { expect(subject).to contain_class 'letsencrypt' }

  it 'should use a staging host for letsencrypt' do
    expect(subject).to contain_class('letsencrypt').with({
        :config => {
          "email" => 'tyler@monkeypox.org',
          "server" => "https://acme-staging.api.letsencrypt.org/directory",
        },
    })
  end

end
