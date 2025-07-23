# Devcontainer for ansible-role-aptly

This devcontainer provides a complete testing environment for the ansible-role-aptly, enabling comprehensive testing of the Aptly Debian repository manager role.

## Features

- **Ubuntu Noble base**: Matches the target platform for aptly
- **Ansible ecosystem**: Latest Ansible, ansible-lint, molecule, and yamllint
- **Systemd support**: Enables testing of service management tasks
- **Port forwarding**: Aptly API accessible on port 8080
- **Testing tools**: Molecule with Docker driver for integration testing

## Prerequisites

- Docker
- Visual Studio Code with Dev Containers extension

## Quick Start

1. Open this repository in VS Code
2. When prompted, click "Reopen in Container" or run the command "Dev Containers: Reopen in Container"
3. Wait for the container to build and setup to complete
4. Start testing your ansible role!

## Available Testing Commands

### Basic Role Testing
```bash
# Check role syntax
ansible-playbook tests/test.yml --syntax-check

# Lint the role
ansible-lint .

# Test YAML formatting
yamllint .
```

### Molecule Testing
```bash
# Run full molecule test suite
molecule test

# Run individual molecule steps
molecule create    # Create test instances
molecule converge  # Run the role
molecule verify    # Run verification tests
molecule destroy   # Clean up
```

### Local Role Execution
```bash
# Run the role against localhost (requires sudo in container)
ansible-playbook tests/test.yml -i tests/inventory

# Run with specific variables
ansible-playbook tests/test.yml -i tests/inventory -e aptly_company_name=mycompany
```

## Testing Infrastructure

- **Container OS**: Ubuntu Noble (24.04 LTS)
- **Systemd**: Configured for service testing
- **Aptly API**: Forwarded to host port 8080 for verification
- **Test Structure**: Located in `tests/` directory

## Customization

### Environment Variables
No special environment variables are required for basic testing.

### Molecule Configuration
The setup script automatically initializes a basic molecule configuration if none exists. You can customize the `molecule/default/` directory for advanced testing scenarios.

### Test Playbooks
Modify `tests/test.yml` to adjust role variables or add additional test scenarios.

## Troubleshooting

### Container Build Issues
- Ensure Docker has sufficient resources allocated
- Check that no other containers are using conflicting ports

### Role Testing Issues
- Verify systemd is running: `systemctl status`
- Check Aptly API accessibility: `curl localhost:8080/api/repos`
- Review Ansible logs for specific error details

### Molecule Issues
- Ensure Docker socket is accessible within the container
- Check molecule configuration in `molecule/default/molecule.yml`

## Files Created by Setup

- `tests/test.yml` - Basic role test playbook
- `tests/inventory` - Local testing inventory
- `molecule/` - Molecule testing configuration (if initialized) 
