require_relative './../spec_helper'

describe 'Resources Lego' do
    describe file('/home/k8s/resources/lego') do
        it { should be_directory }
        it { should be_owned_by 'k8s' }
        it { should be_readable }
    end
    describe file('/home/k8s/resources/lego/namespace.yaml') do
        it { should be_file }
        it { should be_owned_by 'k8s' }
        it { should be_readable }
        its(:content_as_yaml){
            should include('kind' => 'Namespace')
        }
    end
    describe file('/home/k8s/resources/lego/configmap.yaml') do
        it { should be_file }
        it { should be_owned_by 'k8s' }
        it { should be_readable }
        its(:content_as_yaml){
            should include('kind' => 'ConfigMap')
        }
    end
    describe file('/home/k8s/resources/lego/deployment.yaml') do
        it { should be_file }
        it { should be_owned_by 'k8s' }
        it { should be_readable }
        its(:content_as_yaml){
            should include('kind' => 'Deployment')
        }
    end
end
