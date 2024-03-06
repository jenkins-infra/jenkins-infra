Vagrant.configure("2") do |config|
    ubuntu_version = ENV.fetch('UBUNTU_VERSION') { '22.04' }
    mounts_per_version = {
        "18.04" => ["/var/lib/docker"],
        "22.04" => ["/var/lib/docker", "/sys/fs/cgroup:/sys/fs/cgroup:rw"],
    }

    ## Docker provider
    config.vm.provider "docker" do |d|
        d.build_dir = "./vagrant-docker/"
        d.dockerfile = "Dockerfile.#{ubuntu_version}"
        d.create_args = [
            "--privileged=true",
            "--cgroupns=host",
        ]
        d.volumes = mounts_per_version[ubuntu_version]
        d.has_ssh = true
    end

    # Add a secondary NIC ("private" network simulation for roles such as openvpn)
    config.vm.network "private_network", ip: "192.168.0.10", netmask: 24, docker_network__internal: true, docker_network__gateway: "192.168.0.1"

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
                puppet.environment = "vagrant"
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
