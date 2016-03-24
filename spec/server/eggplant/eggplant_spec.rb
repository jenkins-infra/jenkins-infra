require_relative './../spec_helper'

describe 'eggplant' do
  it_behaves_like "an OSU hosted machine"
  it_behaves_like 'a static site host'
  it_behaves_like 'a Docker host'

  context 'accountapp' do
    describe file('/etc/accountapp/config.properties') do
      it { should be_file }
      its(:content) { should match /server=ldap/ }
    end
  end
end
