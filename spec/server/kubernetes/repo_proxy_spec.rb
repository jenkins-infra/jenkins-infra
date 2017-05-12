require_relative './../spec_helper'

describe 'Resources Plugins Jenkins' do
    describe file('/home/k8s/resources/repo_proxy') do
        it { should be_directory }
        it { should be_owned_by 'k8s' }
        it { should be_readable }
    end
    describe file('/home/k8s/resources/repo_proxy/ingress-tls.yaml') do
        it { should be_file }
        it { should be_owned_by 'k8s' }
        it { should be_readable }
        its(:content_as_yaml){
            should include('kind' => 'Ingress')
        }
    end
    describe file('/home/k8s/resources/repo_proxy/secret.yaml') do
        it { should be_file }
        it { should be_owned_by 'k8s' }
        it { should be_readable }
        its(:content_as_yaml){
            should include('kind' => 'Secret')
        }
    end
    describe file('/home/k8s/resources/repo_proxy/deployment.yaml') do
        it { should be_file }
        it { should be_owned_by 'k8s' }
        it { should be_readable }
        its(:content_as_yaml){
            should include('kind' => 'Deployment')
        }
    end
    describe file('/home/k8s/resources/repo_proxy/service.yaml') do
        it { should be_file }
        it { should be_owned_by 'k8s' }
        it { should be_readable }
        its(:content_as_yaml){
            should include('kind' => 'Service')
        }
    end
end
