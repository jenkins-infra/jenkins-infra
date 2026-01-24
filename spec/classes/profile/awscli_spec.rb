require "spec_helper"

describe "profile::awscli" do
  let(:facts) do
    {
      :rspec_hieradata_fixture => "profile_awscli",
    }
  end

  it {
    expect(subject).to contain_file("/foo/bar").with(
      :ensure => "directory",
    )
  }

  it {
    expect(subject).to contain_file("/tmp/FB5DB77FD5C118B80511ADA8A6310ACC4672475C.pub")
  }

  ["gpg", "curl", "unzip"].each do |package|
    it { expect(subject).to contain_package(package) }
  end

  it { expect(subject).to contain_exec("Load AWS CLI Public Key into the GPG agent") }
  it { expect(subject).to contain_exec("Download AWS CLI Installer") }
  it { expect(subject).to contain_exec("Download AWS CLI Installer Signature") }
  it { expect(subject).to contain_exec("Verify downloaded AWS CLI Installer") }
  it { expect(subject).to contain_exec("Cleanup AWS CLI Installer") }
end
