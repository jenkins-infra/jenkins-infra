require 'spec_helper'

describe 'profile::javadoc' do
  let(:params) do
    {
      'site_root' => '/tmp/rspec-javadoc-root'
    }
  end

  it { should contain_class 'profile::javadoc' }
  it { should contain_class 'apache' }

  it { should_not contain_file(params[:site_root]).with_ensure(:directory) }

  context 'Apache VirtualHosts' do
    it { should_not contain_apache__vhost('javadoc.jenkins.io') }
  end

  context 'updating' do
    it 'should contain a cron to update the javadoc' do
      expect(subject).to_not contain_cron('update javadoc.jenkins.io').with(
        'user' => 'www-data'
      )
    end
  end
end
