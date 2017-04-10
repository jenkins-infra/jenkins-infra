require_relative './../spec_helper'

describe 'Resources Kube State Metrics' do
    describe file('/home/k8s/resources/kube_state_metrics') do
        it { should be_directory }
        it { should be_owned_by 'k8s' }
        it { should be_readable }
    end
    describe file('/home/k8s/resources/kube_state_metrics/deployment.yaml') do
        it { should be_file }
        it { should be_owned_by 'k8s' }
        it { should be_readable }
        its(:content_as_yaml){
            should include('kind' => 'Deployment')
        }
    end
    describe file('/home/k8s/resources/kube_state_metrics/service.yaml') do
        it { should be_file }
        it { should be_owned_by 'k8s' }
        it { should be_readable }
        its(:content_as_yaml){
            should include('kind' => 'Service')
        }
    end
end
