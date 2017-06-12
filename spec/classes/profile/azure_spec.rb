require 'spec_helper'

describe 'profile::azure' do
  it { should compile }

  context 'cli => true' do
    let(:params) do
      {
        :cli => true,
      }
    end

    context 'system requirements' do
      it { should contain_package 'python-pip' }
    end

    it 'should remove the azure-cli from pip' do
      expect(subject).to contain_package('azure-cli-python').with({
        :provider => :pip,
        :ensure => :absent,
      })
    end

    it { should contain_apt__source('azure-cli') }
    it { should contain_package('azure-cli') }
  end
end
