require 'spec_helper'

describe 'profile::firewall' do
  it { expect(subject).to contain_class 'firewall' }

  context 'firewall rules' do
    [
      '000 accept icmp traffic',
      '001 accept ssh traffic',
      '002 accept local traffic',
      '003 accept established connections',
    ].each do |rule|
      it { expect(subject).to contain_firewall(rule).with_action('accept') }
    end

    it { expect(subject).to contain_firewall('999 drop all other requests').with_action('drop') }
  end
end
