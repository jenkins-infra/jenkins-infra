require 'spec_helper'

describe 'profile::openvpn' do

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
  
  let(:facts) do
    {
      :rspec_hieradata_fixture => 'profile_openvpn',
    }
  end

  it { expect(subject).to contain_class 'stdlib' }
  it { expect(subject).to contain_class 'profile::docker' }

  it { expect(subject).to contain_package 'net-tools' }

  it { expect(subject).to contain_firewall '107 accept incoming 443 connections' }

  # Routing from VPN networks to eth0 network
  it { expect(subject).to contain_firewall "100 allow routing from 127.0.10.0/24 to 192.168.0.0/24 on ports 80/443" } #.with('outiface' => 'eth0') }
  it { expect(subject).to contain_firewall "100 allow routing from 172.19.0.0/24 to 192.168.0.0/24 on ports 80/443" }

  # Routing from VPN networks to eth1 network
  it { expect(subject).to contain_firewall "100 allow routing from 127.0.10.0/24 to 192.168.100.0/24 on ports 80/443" }
  it { expect(subject).to contain_firewall "100 allow routing from 172.19.0.0/24 to 192.168.100.0/24 on ports 80/443" }

  # Routing from VPN networks to eth1 peered networks
  it { expect(subject).to contain_firewall "100 allow routing from 127.0.10.0/24 to 10.0.0.0/16 on ports 80/443" }
  it { expect(subject).to contain_firewall "100 allow routing from 172.19.0.0/24 to 10.0.0.0/16 on ports 80/443" }
  it { expect(subject).to contain_exec "addroute 10.0.0.0 through 192.168.100.1 (NIC eth1)" }
end
