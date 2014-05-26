require_relative './../spec_helper'

describe 'spinach' do
  it_behaves_like "a standard Linux machine"

  context 'groovy support' do
    describe file('/etc/profile.d/groovy.sh') do
      it { should be_file }
    end

    describe file('/opt/groovy-2.3.1/bin/groovy') do
      it { should be_file }
    end
  end
end
