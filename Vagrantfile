# Required plugins:
#    vagrant-aws
#    vagrant-serverspec

Vagrant.configure("2") do |config|
  access_key_id = ENV['AWS_ACCESS_KEY_ID'] || File.read('.vagrant_key_id').chomp
  secret_access_key = ENV['AWS_SECRET_ACCESS_KEY'] || File.read('.vagrant_secret_access_key').chomp
  keypair = ENV['AWS_KEYPAIR_NAME'] || File.read('.vagrant_keypair_name').chomp

  # prefer aws provider over virtualbox to make it the default
  config.vm.provider 'aws'
  config.vm.provider 'virtualbox'

  config.vm.box = 'dummy'
  config.vm.box_url = 'https://github.com/mitchellh/vagrant-aws/raw/master/dummy.box'

  # modules/account/.travis.yml has incorrect link target, and this blows up
  # when vagrant tries to rsync files as it tries to resolves symlinks.
  # see http://www.trilithium.com/johan/2011/09/delete-broken-symlinks/
  `find -L . -type l -delete`

  config.vm.provider(:aws) do |aws, override|
    aws.access_key_id = access_key_id
    aws.secret_access_key = secret_access_key
    aws.keypair_name = keypair

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
      puts ">> no serverspec defined for #{veggie}"
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
  wget -q http://apt.puppetlabs.com/puppetlabs-release-trusty.deb
  dpkg -i puppetlabs-release-trusty.deb
  apt-get update && apt-get install -yq puppet-agent && touch /apt-cached;
  gem install --no-ri --no-rdoc deep_merge
fi

cd /vagrant
set -xe

export FACTER_vagrant=1
export FACTER_veggie=#{veggie}
export FACTER_clientcert=#{veggie}
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
