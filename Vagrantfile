# Required plugins:
#    vagrant-serverspec

Vagrant.configure("2") do |config|

    # prefer aws provider over virtualbox to make it the default
    # Ubuntu 20.04
    # config.vm.box = 'ubuntu/focal64'

    # Ubuntu 18.04
    config.vm.box = 'ubuntu/bionic64'

    # modules/account/.travis.yml has incorrect link target, and this blows up
    # when vagrant tries to rsync files as it tries to resolves symlinks.
    # see http://www.trilithium.com/johan/2011/09/delete-broken-symlinks/
    `find -L . -type l -delete`

    # Ensure we use at least 1GB of Ram to avoir OOM with puppet agent
    config.vm.provider :virtualbox do |v|
        v.memory = 2048
        v.cpus = 2
        v.linked_clone = true if Vagrant::VERSION =~ /^1.8/
        v.gui = false
    end

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
        # also makes sure we're pulling in the latest Puppet 4 from Puppet. This
        # doesn't quite work with the built-in puppet apply provisioner anymore,
        # so we're manually invoking Puppet too!
        node.vm.provision 'shell', :inline => <<-EOF
            if [ ! -f "/apt-cached" ]; then
              wget -q http://apt.puppetlabs.com/puppet-release-bionic.deb
              dpkg -i puppet-release-bionic.deb
              apt-get update && apt-get install -yq puppet-agent && touch /apt-cached;
              /opt/puppetlabs/puppet/bin/gem install --no-document deep_merge
            fi

            cd /vagrant
            set -xe

            export FACTER_vagrant=1
            export FACTER_veggie=#{veggie}
            export FACTER_clientcert=#{veggie}
            export FACTER_hiera_role=#{veggie}
            exec /opt/puppetlabs/bin/puppet apply \
                  --modulepath=dist:modules \
                  --hiera_config=spec/fixtures/hiera.yaml \
                  --execute 'include profile::vagrant\n include role::#{veggie}'
            EOF

            node.vm.provision :serverspec do |spec|
              spec.pattern = "spec/server/#{specfile}/*.rb"
            end
        end
    end
end

# vim: ft=ruby
