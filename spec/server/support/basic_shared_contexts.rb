require 'rspec'

shared_examples "a standard Linux machine" do
  describe port(22) do
    it { should be_listening }
  end

  # Make sure all our usual users are in place
  %w(abayer tyler kohsuke).each do |username|
    describe user(username) do
      it { should exist }
      it { should have_home_directory "/home/#{username}" }
    end
  end
end
