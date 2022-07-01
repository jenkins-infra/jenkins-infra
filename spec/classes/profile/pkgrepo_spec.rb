require 'spec_helper'

describe 'profile::pkgrepo' do
  let(:params) do
    {
      :docroot => '/var/www/rspec',
      :release_root => '/srv/releases/rspec',
    }
  end

  it 'should ensure the docroot exists' do
    expect(subject).to contain_file(params[:docroot]).with({
      :ensure => :directory,
      :owner => 'www-data',
      :mode => '0775',
    })
  end

  it { should contain_class 'profile::pkgrepo' }
  it { should contain_class 'apache' }

  it 'needs createrepo(8) so we can generate repodata' do
    expect(subject).to contain_package('createrepo').with({
      :ensure => :present,
    })
  end

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
            :ensure => :file,
          })
        end
      end
    end

    context 'opensuse repos' do
      variants.each do |variant|
        platform = 'opensuse'
        variant = "-#{variant}" unless variant.nil?
        variant = "#{platform}#{variant}"
        let(:variant_dir) { "#{params[:docroot]}/#{variant}" }

        it "should define an .htaccess file for #{variant} redirects" do
          expect(subject).to contain_file("#{variant_dir}/.htaccess").with({
            :ensure => :present,
          })
        end

        it "should define a repodata/ for #{variant}" do
          expect(subject).to contain_file("#{variant_dir}/repodata").with({
            :ensure => :directory,
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

        it "should define an .htaccess file for #{variant} redirects" do
          expect(subject).to contain_file("#{variant_dir}/.htaccess").with({
            :ensure => :present,
          })
        end

        it "should define a repodata/ for #{variant}" do
          expect(subject).to contain_file("#{variant_dir}/repodata").with({
            :ensure => :directory,
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
    it { should contain_class 'apache::mod::rewrite' }

    it 'should contain an SSL vhost' do
      expect(subject).to contain_apache__vhost('pkg.origin.jenkins.io').with({
        :serveraliases => ['pkg.jenkins-ci.org'],
        :port => 443,
        :ssl => true,
        :docroot => params[:docroot],
        :options => 'Indexes FollowSymLinks MultiViews',
        :override => ['All'],
      })
    end

    it 'should contain a non-ssl vhost for redirecting' do
      expect(subject).to contain_apache__vhost('pkg.origin.jenkins.io unsecured').with({
        :servername => 'pkg.origin.jenkins.io',
        :port => 80,
        :docroot => params[:docroot],
      })
    end

    it "should contain a non-ssl pkg.jenkins-ci.org vhost which doesn't upgrade" do
      expect(subject).to contain_apache__vhost('pkg.jenkins-ci.org').with({
        :port => 80,
        :options => 'Indexes FollowSymLinks MultiViews',
        :override => ['All'],
        :docroot => params[:docroot],
      })
    end
  end

  context 'letsencrypt setup' do
    let(:environment) { 'production' }

    it { should contain_letsencrypt__certonly('pkg.origin.jenkins.io') }
  end
end
