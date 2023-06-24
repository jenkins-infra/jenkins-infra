require 'spec_helper'

describe 'profile::openvpn' do
  let(:facts) do
    {
      :rspec_hieradata_fixture => 'profile_openvpn',
    }
  end

  it { expect(subject).to contain_class 'stdlib' }
  it { expect(subject).to contain_class 'profile::docker' }

  it { expect(subject).to contain_package 'net-tools' }

  it { expect(subject).to contain_firewall '107 accept incoming 443 connections' }
  it { expect(subject).to contain_firewall '107 accept incoming 22 connections' }
  it { expect(subject).to contain_firewallchain('FORWARD:filter:IPv4').with(
    :ensure => 'present',
    :policy => 'accept',
  )}

  # Routing from VPN networks to eth1 network
  it { expect(subject).to contain_firewall "100 allow routing from 127.0.10.0/24 to 192.168.100.0/24 on ports 22/80/443/5432" }

  # Routing from VPN networks to eth1 peered networks
  it { expect(subject).to contain_firewall "100 allow routing from 127.0.10.0/24 to 10.0.0.0/16 on ports 22/80/443/5432" }
  it { expect(subject).to contain_exec "addroute 10.0.0.0 through 192.168.100.1 (NIC eth1)" }

  # Disable network config in cloud-init if there is more than two network interfaces
  context 'with 3 network interfaces' do
    let(:facts) do
      {
        :rspec_hieradata_fixture => 'profile_openvpn',
      }
    end

    it { expect(subject).to contain_file '/etc/cloud/cloud.cfg.d/99-disable-network-config.cfg' }
  end

  context 'with 2 network interfaces' do
    let(:facts) do
      {
        :rspec_hieradata_fixture => 'profile_openvpn_two_interfaces',
      }
    end

    it { expect(subject).not_to contain_file '/etc/cloud/cloud.cfg.d/99-disable-network-config.cfg' }
  end
end
