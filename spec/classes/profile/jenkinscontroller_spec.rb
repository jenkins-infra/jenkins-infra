require "spec_helper"

describe "profile::jenkinscontroller" do
  let(:fqdn) { "rspec.jenkins.io" }
  let(:params) do
    {
      :ci_fqdn => fqdn,
    }
  end
  let(:facts) do
    {
      :rspec_hieradata_fixture => "profile_jenkinscontroller",
    }
  end

  context "Jenkins configuration" do
    it {
      is_expected.to contain_user("jenkins").with(
        "ensure" => "present",
        "home" => "/var/lib/jenkins",
      )
    }

    it {
      is_expected.to contain_group("jenkins").with(
        "ensure" => "present",
      )
    }

    # https://issues.jenkins-ci.org/browse/INFRA-916
    context "as a Docker container" do
      it { expect(subject).to contain_file("/var/lib/jenkins").with_ensure("directory") }
      it { expect(subject).to contain_class "profile::docker" }

      it "should define a suitable docker::run" do
        expect(subject).to contain_docker__run("jenkins").with({
          :pull_on_start => true,
          :volumes => ["/var/lib/jenkins:/var/jenkins_home:rw"],
        })
      end
    end

    context "Init groovy script" do
      it {
        is_expected.to contain_file("/var/lib/jenkins/init.groovy.d").with(
          "ensure" => "directory",
          "purge" => "true",
          "recurse" => "true",
        )
      }
      context "By default: Init Groovy directory" do
        it { is_expected.not_to contain_file("/var/lib/jenkins/init.groovy.d/enable-ssh-port.groovy") }
        it { is_expected.not_to contain_file("/var/lib/jenkins/init.groovy.d/set-up-git.groovy") }
      end
    end

    context "JCasC" do
      it { is_expected.to contain_file("/var/lib/jenkins/casc.d").with("ensure" => "directory") }
      it { is_expected.to contain_file("/var/lib/jenkins/casc.d/clouds.yaml") }
      it { expect(subject).to contain_exec("install-plugin-configuration-as-code") }
      it { expect(subject).to contain_exec("perform-jcasc-reload") }
      it { expect(subject).to contain_exec("safe-restart-jenkins") }
    end
  end

  context "JNLP" do
    it "should open the JNLP port in the firewall" do
      expect(subject).to contain_firewall("803 Expose JNLP port").with({
        :dport => 50000,
        :proto => "tcp",
        :action => "accept",
      })
    end
  end

  context "with awscli in the container" do
    let(:fqdn) { "rspec.jenkins.io" }
    let(:params) do
      {
        :ci_fqdn => fqdn,
        :tools_versions => {
          :awscli => "2.13.0",
        },
      }
    end
    let(:facts) do
      {
        :rspec_hieradata_fixture => "profile_jenkinscontroller",
      }
    end

    it "should install the unzip package as a requirement to install the aws CLI" do
      expect(subject).to contain_package("unzip")
    end

    it "should mount the aws CLI installation directory in the container with an updated PATH" do
      expect(subject).to contain_docker__run("jenkins").with({
        :pull_on_start => true,
        :volumes => ["/var/lib/jenkins:/var/jenkins_home:rw", "/var/awscli:/var/awscli:ro"],
        :env => [
          "HOME=/var/jenkins_home",
          "USER=jenkins",
          "JAVA_OPTS=-server -Xlog:gc*=info,ref*=debug,ergo*=trace,age*=trace:file=/var/jenkins_home/gc/gc.log::filecount=5,filesize=40M -XX:+UnlockExperimentalVMOptions -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:+UnlockDiagnosticVMOptions -Duser.home=/var/jenkins_home -Djenkins.install.runSetupWizard=false -Djenkins.model.Jenkins.slaveAgentPort=50000 -Dhudson.model.WorkspaceCleanupThread.retainForDays=2 -Dorg.jenkinsci.plugins.workflow.steps.durable_task.DurableTaskStep.USE_WATCHING=true -Dcasc.jenkins.config=/var/jenkins_home/casc.d         -Dcasc.reload.token=SuperSecretThatShouldBeEncryptedInProduction",
          "JENKINS_OPTS=--httpKeepAliveTimeout=60000",
          "LANG=C.UTF-8",
          "PATH=/var/awscli/v2/current/bin/:/opt/java/openjdk/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
        ],
      })
    end
  end

  context "with plugins" do
    let(:params) do
      {
        :plugins => ["workflow-aggregator"],
      }
    end

    it { expect(subject).to contain_profile__jenkinsplugin("workflow-aggregator") }
    it { expect(subject).to contain_exec("install-plugin-workflow-aggregator") }
  end

  context "firewall rules" do
    it { expect(subject).to contain_class "profile::firewall" }

    it "should ensure nothing talks directly to Jenkins" do
      expect(subject).to contain_firewall("801 Allow Jenkins web access only on localhost").with({
        :dport => 8080,
        :action => :accept,
        :iniface => "lo",
      })

      expect(subject).to contain_firewall("802 Block external Jenkins web access").with({
        :dport => 8080,
        :action => :drop,
      })
    end
  end
end
