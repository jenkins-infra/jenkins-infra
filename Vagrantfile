Vagrant.configure("2") do |config|
    ## Docker provider
    config.vm.provider "docker" do |d|
        d.build_dir = "./vagrant-docker/"
        d.create_args = [
            "--privileged=true",
            "--cgroupns=host",
        ]
        d.volumes = [
            "/sys/fs/cgroup:/sys/fs/cgroup:rw",
            "/var/lib/docker",
        ]
        d.has_ssh = true
    end

    config.vm.network "forwarded_port", guest: 80, host: 80
    config.vm.network "forwarded_port", guest: 443, host: 443
    config.vm.network "forwarded_port", guest: 8080, host: 8080

    role_dir = './dist/role/manifests/'
    Dir["#{role_dir}**/*.pp"].each do |role|
        next if File.directory? role
        # Turn `dist/role/manifests/spinach.pp` into `spinach`
            veggie = role.gsub(role_dir, '').gsub('/', '::').gsub('.pp', '')
            specfile = veggie.gsub('::', '_')

        # If there are no serverspec files, we needn't provision a machine!
        if Dir["./spec/server/#{specfile}/*.rb"].empty?
            STDERR.write(">> no serverspec defined for #{veggie}\n")
        next
        end

        config.vm.define(veggie) do |node|
            # https://www.vagrantup.com/docs/provisioning/puppet_apply
            node.vm.provision "puppet" do |puppet|
                puppet.binary_path = "/opt/puppetlabs/bin"
                puppet.module_path = ["dist","modules"]
                puppet.facter = {
                    "vagrant"    => "1",
                    "veggie"     => veggie,
                    "clientcert" => veggie,
                    "hiera_role" => veggie,

                }
                puppet.working_directory = "/vagrant"
                puppet.manifests_path = "manifests"
                puppet.manifest_file = "site.pp"
                puppet.options = "--hiera_config=/vagrant/vagrant-docker/hiera.yaml --execute 'require profile::vagrant\n include role::#{veggie}'"
            end
        end
    end
end

# vim: ft=ruby
