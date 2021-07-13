require 'spec_helper'

describe 'profile::azure' do
  it { should compile }

  context 'cli => true' do
    let(:params) do
      {
        :cli => true,
      }
    end

    it { should contain_apt__source('azure-cli') }
    it { should contain_package('azure-cli') }
  end
end
