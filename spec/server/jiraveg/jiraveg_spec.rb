require_relative './../spec_helper'

describe 'jiraveg' do
  it_behaves_like "a standard Linux machine"

  describe service('jira') do
    it { should be_enabled   }
    it { should be_running   }
  end

  describe port(8080) do
    it { should be_listening }
  end
end
