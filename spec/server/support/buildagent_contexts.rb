require 'rspec'

shared_examples "a Jenkins build agent" do
  it_behaves_like 'a Docker host'

  describe user('jenkins') do
    it { expect(subject).to exist }
    it { expect(subject).to have_home_directory '/home/jenkins' }
  end

  describe file('/home/jenkins/.ssh/authorized_keys') do
    it { expect(subject).to be_file }
  end
end
