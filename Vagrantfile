# Required plugins:
#    vagrant-aws
#    vagrant-serverspec

Vagrant.configure("2") do |config|

    # prefer aws provider over virtualbox to make it the default
    config.vm.box = 'ubuntu/bionic64'

    # modules/account/.travis.yml has incorrect link target, and this blows up
    # when vagrant tries to rsync files as it tries to resolves symlinks.
    # see http://www.trilithium.com/johan/2011/09/delete-broken-symlinks/
    `find -L . -type l -delete`

    # Ensure we use at least 1GB of Ram to avoir OOM with puppet agent
    config.vm.provider :virtualbox do |v|
        v.memory = 1024
        v.cpus = 2
        v.linked_clone = true if Vagrant::VERSION =~ /^1.8/
        v.gui = false
    end

    config.vm.provider(:aws) do |aws, override|
        override.vm.box = 'dummy'
        override.vm.box_url = 'https://github.com/mitchellh/vagrant-aws/raw/master/dummy.box'

        # Get AWS credentials from local files or ENV
        if File.file?('.vagrant_key_id') && \
                File.file?('.vagrant_secret_access_key') && \
                File.file?('.vagrant_keypair_name')
            aws.access_key_id = File.read('.vagrant_key_id').chomp
            aws.secret_access_key = File.read('.vagrant_secret_access_key').chomp
            aws.keypair_name = File.read('.vagrant_keypair_name').chomp
        elsif ENV.has_key?('AWS_ACCESS_KEY_ID') && \
                ENV.has_key?('AWS_SECRET_ACCESS_KEY') && \
                ENV.has_key?('AWS_KEYPAIR_NAME')
            aws.access_key_id = ENV['AWS_ACCESS_KEY_ID'] 
            aws.secret_access_key = ENV['AWS_SECRET_ACCESS_KEY']
            aws.keypair_name = ENV['AWS_KEYPAIR_NAME']
        end

        # Ubuntu LTS 14.04 in us-west-2 stock
        aws.ami = 'ami-9abea4fb'
        aws.region = 'us-west-2'
        aws.instance_type = 'm3.medium'

        override.ssh.username = "ubuntu"
        override.ssh.private_key_path = File.expand_path('~/.ssh/id_rsa')
        override.nfs.functional = false   # https://github.com/mitchellh/vagrant/issues/1437
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
            node.vm.provider(:aws) do |aws, override|
                aws.tags = {
                    :Name => veggie
                }
            end

        # This is a Vagrant-local hack to make sure we have properly updated apt
        # caches since AWS machines are definitely going to have stale ones. It
        # also makes sure we're pulling in the latest Puppet 4 from Puppet. This
        # doesn't quite work with the built-in puppet apply provisioner anymore,
        # so we're manually invoking Puppet too!
        node.vm.provision 'shell', :inline => <<-EOF
            if [ ! -f "/apt-cached" ]; then
              wget -q http://apt.puppetlabs.com/puppet5-release-bionic.deb
              dpkg -i puppet5-release-bionic.deb
              apt-get update && apt-get install -yq puppet-agent && touch /apt-cached;
              /opt/puppetlabs/puppet/bin/gem install --no-ri --no-rdoc deep_merge
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
