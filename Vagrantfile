ENV['VAGRANT_DEFAULT_PROVIDER'] = 'aws'

Vagrant.configure("2") do |config|
  access_key_id = File.read('.vagrant_key_id').chomp
  secret_access_key = File.read('.vagrant_secret_access_key').chomp
  keypair = File.read('.vagrant_keypair_name').chomp

  config.vm.box = 'dummy'

  config.vm.provider(:aws) do |aws, override|
    aws.access_key_id = access_key_id
    aws.secret_access_key = secret_access_key
    aws.keypair_name = keypair

    # Ubuntu LTS 12.04 in us-west-2 with Puppet installed from the Puppet
    # Labs apt repository
    aws.ami = 'ami-665e3756'
    aws.region = 'us-west-2'

    override.ssh.username = "ubuntu"
    override.ssh.private_key_path = File.expand_path('~/.ssh/id_rsa')
  end

  Dir['./dist/role/manifests/*.pp'].each do |role|
    # Turn `dist/role/manifests/spinach.pp` into `spinach`
    veggie = File.basename(role).gsub('.pp', '')

    config.vm.define(veggie) do |node|
      node.vm.provider(:aws) do |aws, override|
        aws.tags = {
          :Name => veggie
        }
      end

      node.vm.provision 'puppet' do |puppet|
        puppet.manifest_file = File.basename(role)
        puppet.manifests_path = File.dirname(role)
        puppet.module_path = ['modules', 'dist']
        # Setting the work to /vagrant so our hiera configuration will resolve
        # properly to our relative hieradata/
        puppet.working_directory = '/vagrant'
        puppet.facter = {
          :vagrant => '1',
        }
        puppet.hiera_config_path = 'spec/fixtures/hiera.yaml'
        puppet.options = "--verbose --execute 'include role::#{veggie}\n include profile::vagrant'"
      end

      node.vm.provision :serverspec do |spec|
        spec.pattern = "spec/server/#{veggie}/*.rb"
      end
    end
  end
end

# vim: ft=ruby
