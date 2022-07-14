require_relative './../spec_helper'

describe 'census_agent' do
  it_behaves_like "a standard Linux machine"

  describe file('/home/jenkins/.ssh/config') do
    it { expect(subject).to be_file }
    it { expect(subject).to contain /Host usage.jenkins.io/ }
    it { expect(subject).to contain /Host census.jenkins.io/ }
  end
end
