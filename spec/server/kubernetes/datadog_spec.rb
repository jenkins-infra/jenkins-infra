require_relative './../spec_helper'

describe 'Resources Datadog' do
    describe file('/home/k8s/resources/datadog') do
        it { should be_directory }
        it { should be_owned_by 'k8s' }
        it { should be_readable } 
    end
    describe file('/home/k8s/resources/datadog/secret.yaml') do
        it { should be_file }
        it { should be_owned_by 'k8s' }
        it { should be_readable } 
        its(:content_as_yaml){
            should include('kind' => 'Secret')
        }
    end
    describe file('/home/k8s/resources/datadog/daemonset.yaml') do
        it { should be_file }
        it { should be_owned_by 'k8s' }
        it { should be_readable } 
        its(:content_as_yaml){
            should include('kind' => 'DaemonSet')
        }
    end
    describe file('/home/k8s/resources/datadog/deployment.yaml') do
        it { should be_file }
        it { should be_owned_by 'k8s' }
        it { should be_readable } 
        its(:content_as_yaml){
            should include('kind' => 'Deployment')
        }
    end
end
