require_relative './../spec_helper'

describe 'jenkins_master' do
  it_behaves_like "a standard Linux machine"

  context 'the jenkins service' do
    describe service('jenkins') do
      it { should be_enabled }
      it { should be_running }
    end

    describe port(8080) do
      it { should be_listening }
    end
  end

  context 'apache' do
    describe service('apache2') do
      it { should be_enabled }
      it { should be_running }
    end

    describe port(80) do
      it { should be_listening }
    end

    describe port(443) do
      it { should be_listening }
    end
  end
end
