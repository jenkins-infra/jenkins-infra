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

        # This is a Vagrant-local hack to make sure we have properly updated apt
        # caches since AWS machines are definitely going to have stale ones. It
        # also makes sure we're pulling in the latest Puppet 6 from Puppet. This
        # doesn't quite work with the built-in puppet apply provisioner anymore,
        # so we're manually invoking Puppet too!
        node.vm.provision 'shell', :inline => <<-EOF
            export DEBIAN_FRONTEND=noninteractive
            if [ ! -f "/apt-cached" ]; then
                ubuntu_codename="$(grep UBUNTU_CODENAME /etc/os-release | cut -d= -f2)"
                package_name="puppet6-release-${ubuntu_codename}.deb"
                wget -q "http://apt.puppetlabs.com/${package_name}"
                dpkg -i "${package_name}"
                rm -f "${package_name}"
                apt-get update --quiet
                apt-get install --no-install-recommends --yes --quiet puppet-agent
                touch /apt-cached
            fi

            cd /vagrant
            set -xe

            export FACTER_kind=vagrant
            export FACTER_veggie=#{veggie}
            export FACTER_clientcert=#{veggie}
            export FACTER_hiera_role=#{veggie}
            exec /opt/puppetlabs/bin/puppet apply \
                --modulepath=dist:modules \
                --hiera_config=hiera.yaml \
                --execute 'require profile::vagrant\n include role::#{veggie}'
            EOF
        end
    end
end

# vim: ft=ruby
