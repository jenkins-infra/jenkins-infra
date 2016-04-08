require 'spec_helper'

describe 'role::buildnode::mac' do
  it { should contain_class 'profile::base' }

  it 'should be a docker-less build node' do
    expect(subject).to contain_class('profile::buildslave').with({
      :docker => false,
      :ruby => false,
    })
  end
end
