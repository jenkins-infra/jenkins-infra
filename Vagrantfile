# Required plugins:
#    vagrant-aws
#    vagrant-serverspec
ENV['VAGRANT_DEFAULT_PROVIDER'] = 'virtualbox'

$vagrant_script = <<SCRIPT
#!/bin/bash
sudo aptitude install -y postgresql postgresql-client

sudo -u postgres -i  createdb jira
sudo -u postgres -i  psql -S jira -c "create user jiraadm password 'mypassword';"
sudo -u postgres -i  psql -S jira -c "GRANT ALL PRIVILEGES ON DATABASE jira TO jiraadm;"

sudo /etc/init.d/postgresql start
SCRIPT

Vagrant.configure("2") do |config|

  config.vm.box = 'dummy'
  config.vm.box_url = 'https://github.com/mitchellh/vagrant-aws/raw/master/dummy.box'

  config.vm.provider(:aws) do |aws, override|
    access_key_id = ENV['AWS_ACCESS_KEY_ID'] || File.read('.vagrant_key_id').chomp
    secret_access_key = ENV['AWS_SECRET_ACCESS_KEY'] || File.read('.vagrant_secret_access_key').chomp
    keypair = ENV['AWS_KEYPAIR_NAME'] || File.read('.vagrant_keypair_name').chomp

    aws.access_key_id = access_key_id
    aws.secret_access_key = secret_access_key
    aws.keypair_name = keypair
    # Ubuntu LTS 12.04 in us-west-2 with Puppet installed from the Puppet
    # Labs apt repository, with a Docker capable (3.8) Linux kernel
    aws.ami = 'ami-69db9b59'
    aws.region = 'us-west-2'
    aws.instance_type = 't1.micro'

    override.ssh.username = "ubuntu"
    override.ssh.private_key_path = File.expand_path('~/.ssh/id_rsa')
  end

  # for local development
  config.vm.provider "virtualbox" do |vb, override|
    override.vm.box = 'ubuntu-server-12042-x64-vbox4210'
    override.vm.box_url = 'http://puppet-vagrant-boxes.puppetlabs.com/ubuntu-server-12042-x64-vbox4210.box'

    # config.vm.network :private_network, :adapter => 1
    config.vm.network "public_network", :adapter => 2

    vb.gui = true
    vb.memory = 3000
    vb.cpus = 2
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



      # This is a Vagrant-local hack to make sure we have properly udpated apt
      # caches since AWS machines are definitely going to have stale ones
      node.vm.provision 'shell',
        :inline => 'if [ ! -f "/apt-cached" ]; then apt-get update && touch /apt-cached; fi'
      node.vm.provision 'shell',
        :inline => $vagrant_script

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
        puppet.options = "--verbose --debug --execute 'include role::#{veggie}\n include profile::vagrant'"
      end

      node.vm.provision :serverspec do |spec|
        spec.pattern = "spec/server/#{veggie}/*.rb"
      end
    end
  end
end

# vim: ft=ruby
