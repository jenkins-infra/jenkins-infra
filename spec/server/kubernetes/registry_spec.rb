require_relative './../spec_helper'

describe 'Resources Lego' do
    describe file('/home/k8s/resources/registry') do
        it { should be_directory }
        it { should be_owned_by 'k8s' }
        it { should be_readable }
    end
    describe file('/home/k8s/resources/registry/secret.yaml') do
        it { should be_file }
        it { should be_owned_by 'k8s' }
        it { should be_readable }
        its(:content_as_yaml){
            should include('kind' => 'Secret')
            should include(
                'metadata' => include(
                    'name' => 'jenkins-registry'))
            should include( 'data' => include('.dockerconfigjson'))
        }
    end
end
