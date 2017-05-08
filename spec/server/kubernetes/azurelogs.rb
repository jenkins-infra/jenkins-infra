require_relative './../spec_helper'

describe 'Resources Azurelogs' do
    describe file('/home/k8s/resources/azurelogs') do
        it { should be_directory }
        it { should be_owned_by 'k8s' }
        it { should be_readable } 
    end
    describe file('/home/k8s/resources/azurelogs/secret.yaml') do
        it { should be_file }
        it { should be_owned_by 'k8s' }
        it { should be_readable } 
        its(:content_as_yaml){
            should include('kind' => 'Secret')
        }
    end
end
