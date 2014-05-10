require 'spec_helper'

describe 'role::celery' do
  it { should contain_class 'profile::base' }
  it { should contain_class 'profile::buildslave' }
end
