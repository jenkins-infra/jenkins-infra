require "spec_helper"

describe "profile::azcopy" do
  it { is_expected.to contain_package("azcopy") }
  it { is_expected.to contain_package("azure-cli") }
end
