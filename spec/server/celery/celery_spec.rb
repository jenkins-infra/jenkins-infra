require_relative './../spec_helper'

describe 'celery' do
  it_behaves_like "a standard Linux machine"

  it_behaves_like "a Jenkins build slave"

  # https://issues.jenkins-ci.org/browse/INFRA-909
  describe user('ogondza') do
    it { should exist }
  end
end
