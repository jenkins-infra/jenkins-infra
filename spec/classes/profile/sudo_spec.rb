require 'spec_helper'

describe 'profile::sudo' do
  it { should contain_class 'sudo' }

  it { should contain_sudo__conf 'admins' }
  it { should contain_sudo__conf 'sudo' }
  it { should contain_sudo__conf 'root' }

  it { should contain_sudo__conf 'env-defaults' }
  it { should contain_sudo__conf 'secure-path' }
end
