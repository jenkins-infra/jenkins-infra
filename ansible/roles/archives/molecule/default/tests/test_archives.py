"""
Test suite for Jenkins Archives Server
Mirrors the functionality of spec/server/archives/archives_spec.rb
"""

import os
import pytest
import testinfra.utils.ansible_runner

testinfra_hosts = testinfra.utils.ansible_runner.AnsibleRunner(
    os.environ['MOLECULE_INVENTORY_FILE']).get_hosts('all')


class TestStandardLinuxMachine:
    """Tests that behave like 'a standard Linux machine'"""

    def test_system_is_running(self, host):
        """Test that the system is up and running"""
        assert host.system_info.type == "linux"

    def test_hostname_is_set(self, host):
        """Test that hostname is properly configured"""
        hostname = host.check_output("hostname")
        assert hostname is not None
        assert len(hostname) > 0

    def test_basic_commands_available(self, host):
        """Test that basic system commands are available"""
        commands = ['ls', 'ps', 'grep', 'awk', 'sed', 'curl']
        for cmd in commands:
            assert host.exists(cmd), f"Command {cmd} should be available"


class TestApacheService:
    """Tests for Apache2 service (mirrors Puppet RSpec)"""

    def test_apache_package_installed(self, host):
        """Test that Apache2 package is installed"""
        apache_pkg = host.package("apache2")
        assert apache_pkg.is_installed

    def test_apache_service_enabled(self, host):
        """Test that Apache2 service is enabled"""
        apache_service = host.service("apache2")
        assert apache_service.is_enabled

    def test_apache_service_running(self, host):
        """Test that Apache2 service is running"""
        apache_service = host.service("apache2")
        assert apache_service.is_running

    def test_apache_modules_loaded(self, host):
        """Test that required Apache modules are loaded"""
        required_modules = ['ssl', 'rewrite', 'bw', 'mime']
        apache_modules = host.check_output("apache2ctl -M")
        for module in required_modules:
            assert f"{module}_module" in apache_modules

    def test_apache_configuration_syntax(self, host):
        """Test that Apache configuration syntax is valid"""
        result = host.run("apache2ctl configtest")
        assert result.rc == 0


class TestNetworkPorts:
    """Tests for network ports (mirrors Puppet RSpec)"""

    def test_port_80_listening(self, host):
        """Test that port 80 is listening"""
        assert host.socket("tcp://0.0.0.0:80").is_listening

    def test_port_443_listening(self, host):
        """Test that port 443 is listening"""
        assert host.socket("tcp://0.0.0.0:443").is_listening

    def test_port_873_listening(self, host):
        """Test that rsync port 873 is listening"""
        assert host.socket("tcp://0.0.0.0:873").is_listening


class TestUsers:
    """Tests for user management"""

    def test_mirrorsync_user_exists(self, host):
        """Test that mirrorsync user exists"""
        user = host.user("mirrorsync")
        assert user.exists
        assert user.shell == "/bin/bash"
        assert user.home == "/home/mirrorsync"

    def test_mirrorsync_ssh_directory(self, host):
        """Test that mirrorsync SSH directory exists with correct permissions"""
        ssh_dir = host.file("/home/mirrorsync/.ssh")
        assert ssh_dir.exists
        assert ssh_dir.is_directory
        assert ssh_dir.user == "mirrorsync"
        assert ssh_dir.group == "mirrorsync"
        assert ssh_dir.mode == 0o700

    def test_www_data_in_mirrorsync_group(self, host):
        """Test that www-data user is in mirrorsync group"""
        user = host.user("www-data")
        assert "mirrorsync" in user.groups


class TestDirectories:
    """Tests for directory structure"""

    def test_archives_directory_exists(self, host):
        """Test that archives directory exists with correct permissions"""
        archives_dir = host.file("/srv/releases")
        assert archives_dir.exists
        assert archives_dir.is_directory
        assert archives_dir.user == "www-data"
        assert archives_dir.group == "www-data"
        assert archives_dir.mode == 0o775

    def test_log_directories_exist(self, host):
        """Test that Apache log directories exist"""
        log_dirs = [
            "/var/log/apache2/archives-test.local",
            "/var/log/apache2/archives-legacy-test.local",
            "/var/log/mirrorsync"
        ]
        for log_dir in log_dirs:
            directory = host.file(log_dir)
            assert directory.exists
            assert directory.is_directory


class TestRsyncService:
    """Tests for rsync daemon"""

    def test_rsync_package_installed(self, host):
        """Test that rsync package is installed"""
        rsync_pkg = host.package("rsync")
        assert rsync_pkg.is_installed

    def test_rsync_service_enabled(self, host):
        """Test that rsync service is enabled"""
        rsync_service = host.service("rsync")
        assert rsync_service.is_enabled

    def test_rsync_service_running(self, host):
        """Test that rsync service is running"""
        rsync_service = host.service("rsync")
        assert rsync_service.is_running

    def test_rsyncd_config_exists(self, host):
        """Test that rsyncd.conf exists with correct permissions"""
        config = host.file("/etc/rsyncd.conf")
        assert config.exists
        assert config.is_file
        assert config.user == "root"
        assert config.mode == 0o600

    def test_rsync_motd_exists(self, host):
        """Test that rsync MOTD file exists"""
        motd = host.file("/etc/jenkins.motd")
        assert motd.exists
        assert motd.is_file
        assert motd.user == "root"
        assert motd.mode == 0o644


class TestScripts:
    """Tests for custom scripts"""

    def test_mirrorsync_script_exists(self, host):
        """Test that mirrorsync script exists with correct permissions"""
        script = host.file("/usr/bin/mirrorsync")
        assert script.exists
        assert script.is_file
        assert script.user == "root"
        assert script.mode == 0o755

    def test_log_compression_script_exists(self, host):
        """Test that log compression script exists"""
        script = host.file("/usr/local/bin/compress-rotatelogs.sh")
        assert script.exists
        assert script.is_file
        assert script.user == "root"
        assert script.mode == 0o755


class TestSudoConfiguration:
    """Tests for sudo configuration"""

    def test_mirrorsync_sudo_config(self, host):
        """Test that mirrorsync sudo configuration exists"""
        sudo_config = host.file("/etc/sudoers.d/mirrorsync")
        assert sudo_config.exists
        assert sudo_config.is_file
        assert sudo_config.user == "root"
        assert sudo_config.mode == 0o440

    def test_mirrorsync_sudo_permissions(self, host):
        """Test that mirrorsync can run mirrorsync script via sudo"""
        # Test that the sudoers file contains the correct entry
        content = host.file("/etc/sudoers.d/mirrorsync").content_string
        expected = "mirrorsync ALL=(ALL) NOPASSWD: /usr/bin/mirrorsync"
        assert expected in content


class TestCronJobs:
    """Tests for cron configuration"""

    def test_cron_package_installed(self, host):
        """Test that cron package is installed"""
        cron_pkg = host.package("cron")
        assert cron_pkg.is_installed

    def test_cron_service_running(self, host):
        """Test that cron service is running"""
        cron_service = host.service("cron")
        assert cron_service.is_running

    def test_mirrorsync_cron_job(self, host):
        """Test that mirrorsync cron job is configured"""
        crontab = host.check_output("crontab -l -u mirrorsync")
        assert "mirrorsync" in crontab
        assert "/usr/bin/mirrorsync" in crontab


class TestWebServerConfiguration:
    """Tests for web server virtual hosts and configuration"""

    def test_apache_sites_enabled(self, host):
        """Test that Apache sites are enabled"""
        sites = [
            "archives-test.local-ssl",
            "archives-test.local",
            "archives-legacy-test.local-ssl", 
            "archives-legacy-test.local"
        ]
        for site in sites:
            site_file = host.file(f"/etc/apache2/sites-enabled/{site}.conf")
            assert site_file.exists, f"Site {site} should be enabled"

    def test_apache_mime_types_config(self, host):
        """Test that Apache MIME types configuration is enabled"""
        mime_config = host.file("/etc/apache2/conf-enabled/archives-mime-types.conf")
        assert mime_config.exists

    def test_web_server_responds(self, host):
        """Test that web server responds to HTTP requests"""
        # Test HTTP redirect (should return 3xx redirect)
        result = host.run("curl -s -o /dev/null -w '%{http_code}' http://localhost:80/")
        assert result.stdout in ["301", "302"], "HTTP should redirect to HTTPS"


class TestSecurityConfiguration:
    """Tests for security-related configuration"""

    def test_ufw_package_installed(self, host):
        """Test that UFW firewall package is installed"""
        ufw_pkg = host.package("ufw")
        assert ufw_pkg.is_installed, "UFW package should be installed"

    def test_ufw_firewall_rules_configured(self, host):
        """Test that UFW firewall rules are configured for required ports"""
        # Check that UFW has rules for our required ports
        ufw_status = host.run("ufw status")
        required_ports = ["80", "443", "873"]
        
        for port in required_ports:
            # Look for the port in UFW status output (may show as "80/tcp" or just "80")
            assert port in ufw_status.stdout or f"{port}/tcp" in ufw_status.stdout, \
                f"UFW should have rules for port {port}"

    def test_required_ports_accessible(self, host):
        """Test that required ports are accessible"""
        ports = [80, 443, 873]
        for port in ports:
            socket = host.socket(f"tcp://0.0.0.0:{port}")
            assert socket.is_listening, f"Port {port} should be listening"


class TestDependencyPackages:
    """Tests for required packages"""

    def test_required_packages_installed(self, host):
        """Test that all required packages are installed"""
        required_packages = [
            "apache2",
            "libapache2-mod-bw", 
            "rsync",
            "cron"
        ]
        for package in required_packages:
            pkg = host.package(package)
            assert pkg.is_installed, f"Package {package} should be installed"


@pytest.mark.parametrize("service", [
    "apache2",
    "rsync", 
    "cron"
])
def test_services_are_running(host, service):
    """Parametrized test to ensure all critical services are running"""
    svc = host.service(service)
    assert svc.is_running, f"Service {service} should be running"
    assert svc.is_enabled, f"Service {service} should be enabled" 