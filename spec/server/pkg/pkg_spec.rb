require_relative "./../spec_helper"

describe "pkg" do
  it_behaves_like "a standard Linux machine"

  context "pkg" do
    describe service("apache2") do
      it { expect(subject).to be_enabled }
      it { expect(subject).to be_running }
    end
  end
end
