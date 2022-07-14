require 'rspec'

shared_examples "a Jenkins build agent" do
  it_behaves_like 'a Docker host'

  describe user('jenkins') do
    it { should exist }
    it { should have_home_directory '/home/jenkins' }
  end

  describe file('/home/jenkins/.ssh/authorized_keys') do
    it { should be_file }
  end
end
