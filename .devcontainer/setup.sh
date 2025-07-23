#!/bin/bash
set -e  # Exit on any error

echo "🚀 Setting up ansible-role-aptly development environment..."

# Configure git safe directory
echo "📝 Configuring git safe directory..."
git config --global --add safe.directory /workspaces/ansible-role-aptly

# Install Ansible and related tools via pipx (preferred method for isolated CLI tools)
echo "📦 Installing Ansible via pipx..."
pipx install --include-deps ansible

echo "🧹 Installing ansible-lint..."
pipx install ansible-lint

echo "🧪 Installing molecule with docker support..."
pipx install "molecule[docker]"

echo "🔍 Installing yamllint for YAML validation..."
pipx install yamllint

# Install additional Python packages for Ansible modules
echo "🐍 Installing Python dependencies..."
pip3 install --break-system-packages \
    jmespath \
    netaddr \
    dnspython \
    requests

# Check molecule configuration
if [ ! -d "molecule/default" ]; then
    echo "🧪 Initializing molecule configuration..."
    cd /workspaces/ansible-role-aptly
    if molecule init scenario 2>/dev/null; then
        echo "✅ Molecule configuration created successfully"
    else
        echo "ℹ️  Molecule configuration skipped (can be set up manually if needed)"
    fi
else
    echo "✅ Molecule configuration already exists - all set!"
fi

# Create a simple test playbook for the role
echo "📝 Creating test playbook structure..."
mkdir -p tests
if [ ! -f "tests/test.yml" ]; then
    cat > tests/test.yml << 'EOF'
---
- hosts: localhost
  become: true
  vars:
    aptly_company_name: testcompany
    aptly_key_email: test@example.com
    aptly_repositories:
      - name: "testcompany-dev"
        comment: development packages
        default_distribution: noble
        default_component: main
  roles:
    - ansible-role-aptly
EOF
fi

# Create inventory file for local testing
if [ ! -f "tests/inventory" ]; then
    cat > tests/inventory << 'EOF'
[local]
localhost ansible_connection=local
EOF
fi

# Verify installations
echo "🔍 Verifying installations..."
echo "  ✓ Ansible version: $(ansible --version | head -1)"
echo "  ✓ Ansible-lint version: $(ansible-lint --version)"
echo "  ✓ Molecule version: $(molecule --version)"
echo "  ✓ Yamllint version: $(yamllint --version)"

echo ""
echo "✅ ansible-role-aptly development environment setup complete!"
echo ""
echo "🎯 Quick start commands:"
echo "  • Test role syntax: ansible-playbook tests/test.yml --syntax-check"
echo "  • Lint the role: ansible-lint ."
echo "  • Run molecule tests: molecule test"
echo "  • Run role locally: ansible-playbook tests/test.yml -i tests/inventory"
echo ""
echo "📡 The Aptly API will be available on port 8080 when the role runs" 
