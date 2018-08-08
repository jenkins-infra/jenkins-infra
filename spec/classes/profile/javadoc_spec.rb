require 'spec_helper'

describe 'profile::javadoc' do
  let(:site_root) { '/tmp/rspec-javadoc-root' }
  let(:params) do
    {
      'site_root' => site_root
    }
  end

  it { should contain_class 'profile::javadoc' }
  it { should contain_class 'apache' }

  it {
    should contain_file(site_root).with(
      'ensure' => 'absent'
    )
  }

  context 'Apache VirtualHosts' do
    it { should contain_apache__vhost('javadoc.jenkins.io') }
  end

  context 'updating' do
    it 'should contain a cron to update the javadoc' do
      expect(subject).to contain_cron('update javadoc.jenkins.io').with(
        'ensure' => 'absent'
      )
    end
  end
end
