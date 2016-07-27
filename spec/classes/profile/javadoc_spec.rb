require 'spec_helper'

describe 'profile::javadoc' do
  let(:params) do
    {
      :site_root => '/tmp/rspec-javadoc-root',
    }
  end

  it { should contain_class 'profile::javadoc' }
  it { should contain_class 'apache' }

  it { should contain_file(params[:site_root]).with_ensure(:directory) }

  context 'Apache VirtualHosts' do
    it { should contain_apache__vhost('javadoc.jenkins.io') }

    context 'javadoc.jenkins.io' do
    end
  end

  context 'updating' do
    it 'should contain a cron to update the javadoc' do
      expect(subject).to contain_cron('update javadoc.jenkins.io').with({
        :user => 'www-data',
      })
    end
  end
end
