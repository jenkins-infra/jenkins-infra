# Archives Role

This Ansible role configures a Jenkins archives server with Apache, rsync daemon, and automated mirror synchronization.

## Features

- Apache web server with SSL certificates via Let's Encrypt
- Rsync daemon for read-only mirror access
- Automated mirror synchronization from upstream sources
- User and SSH key management for mirrorsync operations
- Firewall configuration for web and rsync traffic
- Log rotation and compression
- Support for both current and legacy domain names

## Requirements

- Ubuntu 20.04 (focal) or 22.04 (jammy)
- Ansible 2.9 or higher
- Collections: `community.general`, `ansible.posix`

## Role Variables

See `defaults/main.yml` for all available variables. Key variables include:

- `archives_fqdn`: Primary domain name (default: "archives.jenkins.io")
- `archives_legacy_fqdn`: Legacy domain name (default: "archives.jenkins-ci.org")
- `archives_dir`: Archives directory path (default: "/srv/releases")
- `source_mirror_endpoint`: Mirror source endpoint
- `ssh_authorized_keys`: SSH keys for mirrorsync user
- `letsencrypt_email`: Email for Let's Encrypt certificates

## Example Playbook

```yaml
---
- name: Configure Jenkins Archives Server
  hosts: archives
  become: true
  roles:
    - archives
```

## Tags

- `users`: User management tasks
- `sudo`: Sudo configuration
- `packages`: Package installation
- `directories`: Directory creation
- `apache`: Apache configuration
- `ssl`: SSL certificate management
- `rsync`: Rsync daemon configuration
- `sync`: Mirror synchronization
- `firewall`: Firewall rules
- `logging`: Log management
- `services`: Service management

## License

MIT

## Author Information

Jenkins Infrastructure Team 