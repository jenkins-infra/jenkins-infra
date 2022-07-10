require 'spec_helper'

describe 'profile::sudo' do
  it { expect(subject).to contain_class 'sudo' }

  it { expect(subject).to contain_sudo__conf 'admins' }
  it { expect(subject).to contain_sudo__conf 'sudo' }
  it { expect(subject).to contain_sudo__conf 'root' }

  it { expect(subject).to contain_sudo__conf 'env-defaults' }
  it { expect(subject).to contain_sudo__conf 'secure-path' }
end
