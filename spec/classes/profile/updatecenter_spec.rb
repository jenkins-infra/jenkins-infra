require 'spec_helper'

describe 'profile::updatecenter' do
  let(:home_dir) { '/home/rspec' }
  let(:params) do
    {
      :home_dir => home_dir,
    }
  end

  it 'should install the update center rsync private key' do
    expect(subject).to contain_file("#{home_dir}/.ssh/updates-rsync-key").with({
      :ensure => :file,
      :mode   => '0600',
    })
  end

  it 'should concat ~/.ssh/config' do
    expect(subject).to contain_concat("#{home_dir}/.ssh/config").with({
      :ensure => :present,
      :mode   => '0644',
    })

    expect(subject).to contain_concat__fragment('updates-rsync-key concat').with({
      :target => "#{home_dir}/.ssh/config",
    })
  end
end
