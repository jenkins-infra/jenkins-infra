require 'spec_helper'

describe 'profile::l10n_server' do
  it { should contain_class 'docker' }
  it { should contain_user 'l10n' }
  it { should contain_docker__image 'jenkinsciinfra/l10n-server' }
  it { should contain_docker__run 'l10n' }

  it { should contain_service('docker-l10n') }
end
