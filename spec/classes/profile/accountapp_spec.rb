require 'spec_helper'

describe 'profile::accountapp' do
  it { should contain_class 'firewall' }
  it { should contain_class 'profile::docker' }

  describe 'accountapp configuration' do
    it do
      should contain_file('/etc/accountapp').with({
        :ensure => :directory,
      })
    end

    it { should contain_file('/etc/accountapp/config.properties').with_ensure(:file) }
  end

  describe 'accountapp docker image' do
    let(:tag) { 'buildRspec' }
    let(:params) do
      {
        :image_tag => tag,
      }
    end

    it 'should have the right image' do
      expect(subject).to contain_docker__image('jenkinsciinfra/account-app').with({
        :image_tag => tag,
      })
    end

    it 'should run the docker image' do
      expect(subject).to contain_docker__run('account-app').with({
        :command => nil,
        :image => "jenkinsciinfra/account-app:#{tag}",
      })
    end
  end
end
