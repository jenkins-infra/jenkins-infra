require_relative './../spec_helper'

describe 'census_agent' do
  it_behaves_like "a standard Linux machine"

  describe file('/home/jenkins/.ssh/config') do
    it { should be_file }
    it { should contain /Host usage.jenkins.io/ }
  end
end
