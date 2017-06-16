require_relative './../spec_helper'

describe 'Resources Account App' do
    describe file('/home/k8s/resources/accountapp') do
        it { should be_directory }
        it { should be_owned_by 'k8s' }
        it { should be_readable }
    end
    describe file('/home/k8s/resources/accountapp/ingress-tls.yaml') do
        it { should be_file }
        it { should be_owned_by 'k8s' }
        it { should be_readable }
        its(:content_as_yaml){
            should include('kind' => 'Ingress')
        }
    end
    describe file('/home/k8s/resources/accountapp/secret.yaml') do
        it { should be_file }
        it { should be_owned_by 'k8s' }
        it { should be_readable }
        its(:content_as_yaml){
            should include('kind' => 'Secret')
        }
    end
    describe file('/home/k8s/resources/accountapp/service.yaml') do
        it { should be_file }
        it { should be_owned_by 'k8s' }
        it { should be_readable }
        its(:content_as_yaml){
            should include('kind' => 'Service')
        }
    end
    describe file('/home/k8s/resources/accountapp/deployment.yaml') do
        it { should be_file }
        it { should be_owned_by 'k8s' }
        it { should be_readable }
        its(:content_as_yaml){
            should include('kind' => 'Deployment')
        }
    end
end
