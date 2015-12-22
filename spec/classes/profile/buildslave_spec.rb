require 'spec_helper'

describe 'profile::buildslave' do
  it { should contain_class 'ruby' }
  it { should contain_class 'docker' }

  context 'build slave tooling' do
    it { should contain_package 'bundler' }
    # Provided by the `git` module
    it { should contain_package 'git' }
    it { should contain_package 'subversion' }
  end

  context 'managing a `jenkins` user' do
    it { should contain_account 'jenkins' }

    # Keeping these two examples here to make sure a user and group are created
    it { should contain_user 'jenkins' }
    it { should contain_group 'jenkins' }
  end
end
