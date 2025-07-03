# Jenkins Infrastructure Ansible Migration

This directory contains the Ansible playbooks and configuration for the Jenkins infrastructure migration from Puppet to Ansible.

## Structure

```txt
ansible/
├── archives.yml                  # Archives server playbook
├── site.yml                      # Main site playbook
├── ansible.cfg                   # Ansible configuration
├── test.sh                       # Test runner script
├── test-requirements.txt         # Python testing dependencies
├── roles/
│   └── archives/                 # Archives role
│       ├── defaults/
│       │   └── main.yml          # Default variables
│       ├── files/
│       │   ├── compress-rotatelogs.sh  # Log compression script
│       │   └── jenkins.motd      # MOTD for rsync daemon
│       ├── handlers/
│       │   └── main.yml          # Service handlers
│       ├── meta/
│       │   └── main.yml          # Role metadata
│       ├── tasks/
│       │   └── main.yml          # Main tasks
│       ├── templates/
│       │   ├── apache-mime-types.conf.j2      # Apache MIME types
│       │   ├── archives-legacy-redirect.conf.j2  # Legacy HTTP redirect
│       │   ├── archives-legacy-ssl.conf.j2    # Legacy SSL virtual host
│       │   ├── archives-redirect.conf.j2      # HTTP redirect
│       │   ├── archives-ssl.conf.j2           # SSL virtual host
│       │   ├── mirrorsync.sh.j2              # Mirror sync script
│       │   └── rsyncd.conf.j2                # Rsync daemon config
│       ├── molecule/
│       │   └── default/
│       │       ├── molecule.yml          # Molecule test configuration
│       │       ├── requirements.yml      # Galaxy requirements
│       │       ├── converge.yml          # Test playbook
│       │       └── tests/
│       │           └── test_archives.py  # Infrastructure tests
│       ├── test.sh               # Role test script
│       └── README.md             # Role documentation
└── inventory/
    ├── hosts.yml                 # Server inventory
    └── host_vars/
        └── archives.do.jenkins.io.yml  # Host-specific variables
```

## Quick Start

### Prerequisites

- Ansible 2.9+
- Python 3.8+
- Docker (for testing)

### Installation

1. Install Ansible:

   ```bash
   pip install ansible
   ```

2. Install test dependencies:

   ```bash
   pip install -r test-requirements.txt
   ```

3. Install Galaxy collections:

   ```bash
   ansible-galaxy collection install -r molecule/default/requirements.yml
   ```

### Running Tests

Run all tests:

```bash
./test.sh
```

Or run individual test components:

```bash
# Lint playbook
ansible-lint archives.yml

# Run infrastructure tests
cd molecule/default && molecule test
```

### Deployment

Deploy to production:

```bash
ansible-playbook -i inventory/hosts.yml archives.yml
```

Deploy all services:

```bash
ansible-playbook -i inventory/hosts.yml site.yml
```

### Testing Individual Components

For role-based testing:

```bash
# Test the archives role
cd roles/archives
./test.sh

# Or run individual molecule commands
cd roles/archives/molecule/default
molecule create
molecule converge
molecule verify
molecule login
molecule destroy
```

For playbook-based testing:

```bash
# Test the entire playbook
ansible-playbook --syntax-check archives.yml
ansible-playbook --check archives.yml
```

## Current Services

### Archives Server (archives.jenkins.io)

Migrated from Puppet profile `dist/profile/manifests/archives.pp`.

**Features:**

- Apache web server for archived Jenkins releases
- SSL certificates via Let's Encrypt
- Rsync daemon for mirror access
- Automated mirror synchronization
- User management and security configuration

**Files:**

- Playbook: `archives.yml`
- Role: `roles/archives/`
- Variables: `roles/archives/defaults/main.yml`
- Host config: `inventory/host_vars/archives.do.jenkins.io.yml`

**Testing:**

- Molecule tests: `roles/archives/molecule/default/tests/test_archives.py`
- 300+ lines of infrastructure validation

## Migration Status

- [x] Archives server (`archives.jenkins.io`) - Role-based
- [ ] Census server (`census.jenkins.io`)
- [ ] Usage server (`usage.jenkins.io`)
- [ ] Package repository (`pkg.jenkins.io`)
- [ ] OpenVPN servers
- [ ] Jenkins controllers
- [ ] Build agents

## Architecture

The project is migrating from a playbook-based to a role-based architecture:

- **Playbooks**: Simple entry points that use roles
- **Roles**: Self-contained, reusable components with their own tests
- **Inventory**: Host and group variables for customization
- **Collections**: External dependencies managed via Galaxy

### Role Structure

Each role follows the standard Ansible structure:

```
roles/rolename/
├── defaults/main.yml     # Default variables
├── files/               # Static files
├── handlers/main.yml    # Service handlers
├── meta/main.yml        # Role metadata and dependencies
├── tasks/main.yml       # Main tasks
├── templates/           # Jinja2 templates
├── molecule/            # Testing configuration
├── test.sh             # Role test script
└── README.md           # Role documentation
```

## Configuration

### Ansible Configuration

The `ansible.cfg` file provides:

- Optimized SSH settings
- Proper stdout callbacks
- Host key checking disabled for testing
- Inventory and roles paths

### Variables

Variables are organized by role:

- `roles/archives/defaults/main.yml` - Default role variables
- `inventory/host_vars/` - Host-specific overrides

### Inventory

The inventory uses YAML format:

```yaml
all:
  children:
    archives:
      hosts:
        archives.do.jenkins.io:
          ansible_host: 159.89.235.70
```

## Development

### Adding New Services

#### Option 1: Role-based (Recommended)

1. Create a new role directory: `roles/census/`
2. Create role structure: `defaults/`, `tasks/`, `handlers/`, `templates/`, `files/`, `meta/`
3. Add variables in `roles/census/defaults/main.yml`
4. Add host configuration in `inventory/host_vars/`
5. Create Molecule tests in `roles/census/molecule/default/`
6. Create a playbook that uses the role: `census.yml`
7. Update `site.yml` to import the new playbook

#### Option 2: Playbook-based (Not recommended for new services)

1. Create a new playbook file (e.g., `census.yml`)
2. Add variables directly in the playbook or separate files
3. Add host configuration in `inventory/host_vars/`
4. Create separate test infrastructure
5. Update `site.yml` to import the new playbook

### Testing Guidelines

- Always run tests before deployment
- Use Molecule for infrastructure testing
- Include comprehensive test coverage
- Test both success and failure scenarios

### Linting

The project uses ansible-lint with default rules. Common issues:

- Use FQCN for all modules
- Use boolean values (`true/false`) not strings
- Add `changed_when` for command tasks
- Proper naming conventions

## Troubleshooting

### Common Issues

1. **Template not found**: Check path references in playbooks
2. **SSH connection failed**: Verify inventory and SSH keys
3. **Permission denied**: Ensure proper sudo configuration
4. **Docker issues**: Verify Docker is running and accessible

### Debug Mode

Run with verbose output:

```bash
ansible-playbook -i inventory/hosts.yml archives.yml -v
```

### Molecule Debugging

```bash
# Keep container running after failure
molecule converge

# View logs
molecule login
sudo journalctl -u apache2

# Check configuration
molecule login
sudo apache2ctl configtest
```

## Migration Notes

### From Puppet to Ansible

Key differences:

- **Templates**: ERB → Jinja2
- **Variables**: Hiera → Ansible variables
- **Facts**: Puppet facts → Ansible facts
- **Testing**: RSpec → Molecule/Testinfra

### Best Practices

1. **Idempotency**: Ensure tasks can run multiple times
2. **Error handling**: Use proper error handling and rollback
3. **Security**: Follow security best practices
4. **Testing**: Comprehensive test coverage
5. **Documentation**: Keep documentation updated

## Contributing

1. Create feature branch
2. Make changes
3. Run tests: `./test.sh`
4. Submit pull request
5. Update documentation

## Resources

- [Ansible Documentation](https://docs.ansible.com/)
- [Molecule Documentation](https://molecule.readthedocs.io/)
- [Jenkins Infrastructure](https://github.com/jenkins-infra/jenkins-infra)
- [Testinfra Documentation](https://testinfra.readthedocs.io/)
