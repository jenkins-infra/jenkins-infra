require 'spec_helper'

describe 'profile::pkgrepo' do
  let(:params) do
    {
      :docroot => '/var/www/rspec',
      :release_root => '/srv/releases/rspec',
    }
  end

  it { should contain_class 'profile::pkgrepo' }
  it { should contain_class 'apache' }

  context 'repository directories' do
    platforms = ['debian', 'opensuse', 'redhat']
    variants = [nil, 'stable', 'rc', 'stable-rc']

    platforms.each do |platform|
      variants.each do |variant|
        # hyphenate if we have a variant to test
        variant = "-#{variant}" unless variant.nil?
        variant = "#{platform}#{variant}"
        let(:variant_dir) { "#{params[:docroot]}/#{variant}" }

        it "should have a repo directory for #{variant}" do
          expect(subject).to contain_file(variant_dir).with({
            :ensure => :directory,
          })
        end

        it "should install the key for #{variant}" do
          expect(subject).to contain_file("#{variant_dir}/jenkins-ci.org.key").with({
            :ensure => :present,
          })
        end
      end
    end

    context 'redhat repos' do
      variants.each do |variant|
        platform = 'redhat'
        variant = "-#{variant}" unless variant.nil?
        variant = "#{platform}#{variant}"
        let(:variant_dir) { "#{params[:docroot]}/#{variant}" }

        it "should define a jenkins.repo for #{variant}" do
          expect(subject).to contain_file("#{variant_dir}/jenkins.repo").with({
            :ensure => :present,
          })
        end
      end
    end

    context 'debian repos' do
      variants.each do |variant|
        platform = 'debian'
        variant = "-#{variant}" unless variant.nil?
        variant = "#{platform}#{variant}"
        let(:variant_dir) { "#{params[:docroot]}/#{variant}" }

        it "should define an .htaccess to manage redirects for #{variant}" do
          expect(subject).to contain_file("#{variant_dir}/.htaccess").with({
            :ensure => :present,
          })
        end

        it "should have a symbolic link to the direct repo for #{variant}" do
          expect(subject).to contain_file("#{variant_dir}/direct").with({
            :ensure => :link,
            :target => "#{params[:release_root]}/#{variant_dir.split('/')[-1]}",
          })
        end
      end
    end
  end

  context 'apache setup' do
    it 'should contain an SSL vhost' do
      expect(subject).to contain_apache__vhost('pkg.jenkins.io').with({
        :serveraliases => ['pkg.jenkins-ci.org'],
        :port => 443,
        :ssl => true,
        :docroot => params[:docroot],
      })
    end

    it 'should contain a non-ssl vhost for redirecting' do
      expect(subject).to contain_apache__vhost('pkg.jenkins.io unsecured').with({
        :servername => 'pkg.jenkins.io',
        :serveraliases => ['pkg.jenkins-ci.org'],
        :port => 80,
        :docroot => params[:docroot],
        :redirect_status => 'permanent',
        :redirect_dest => ['https://pkg.jenkins.io/'],
      })
    end
  end

  context 'letsencrypt setup' do
    let(:facts) do
      {
        :environment => 'production',
      }
    end

    it { should contain_letsencrypt__certonly('pkg.jenkins.io') }
  end
end
