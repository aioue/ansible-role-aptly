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

# Wait for aptly-client container to be ready
echo "⏳ Waiting for aptly-client container to be ready..."
timeout 60 bash -c 'until docker ps | grep -q aptly-client; do sleep 2; done' || echo "Client container may not be ready yet"

# Prepare aptly-client container with essential packages
echo "🖥️  Preparing aptly-client container..."
docker exec aptly-client bash -c "
    apt-get update -qq &&
    apt-get install -y -qq python3 python3-pip openssh-server sudo curl gnupg2 &&
    useradd -m -s /bin/bash ubuntu &&
    echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers &&
    mkdir -p /home/ubuntu/.ssh &&
    chown ubuntu:ubuntu /home/ubuntu/.ssh
" 2>/dev/null || echo "Note: Client container setup will be done when needed"

# Create test inventory for multi-container setup
echo "📝 Creating multi-container test inventory..."
mkdir -p tests
cat > tests/inventory << 'EOF'
[aptly_servers]
aptly-server ansible_host=172.20.0.10 ansible_user=ubuntu ansible_connection=docker

[aptly_clients]
aptly-client ansible_host=172.20.0.20 ansible_user=ubuntu ansible_connection=docker

[all:vars]
ansible_python_interpreter=/usr/bin/python3
EOF

# Create a test playbook for the multi-container setup
if [ ! -f "tests/test-multicontainer.yml" ]; then
    cat > tests/test-multicontainer.yml << 'EOF'
---
- name: Deploy Aptly server
  hosts: aptly_servers
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
    - role: "{{ playbook_dir }}/.."  # Reference the role from parent directory

- name: Test Aptly from client
  hosts: aptly_clients
  become: true
  tasks:
    - name: Test connection to aptly API
      uri:
        url: http://172.20.0.10:8080/api/version
        method: GET
      register: aptly_version
      
    - name: Display aptly version from client
      debug:
        msg: "Aptly API accessible from client. Version: {{ aptly_version.json.Version }}"
      
    - name: Add aptly repository to client's sources
      apt_repository:
        repo: "deb [trusted=yes] http://172.20.0.10:8080/api/repos/testcompany-dev/packages ./"
        state: present
        filename: aptly-test
      ignore_errors: true  # Repository might not be published yet
EOF
fi

# Create test script
cat > test-aptly.sh << 'EOF'
#!/bin/bash

# Simple test script for aptly functionality
set -e

APTLY_API="http://172.20.0.10:8080/api"

check_containers() {
    echo "🔍 Checking containers..."
    docker ps | grep aptly || echo "Containers may not be running"
}

test_api() {
    echo "🧪 Testing API..."
    curl -s "$APTLY_API/version" || echo "API not accessible yet"
}

deploy() {
    echo "🚀 Deploying Aptly..."
    ansible-playbook -i tests/inventory tests/test-multicontainer.yml
}

case "${1:-help}" in
    "check") check_containers ;;
    "test") test_api ;;
    "deploy") deploy ;;
    *) 
        echo "Usage: $0 [check|test|deploy]"
        echo "  check  - Check container status"
        echo "  test   - Test API connectivity"
        echo "  deploy - Deploy Aptly role"
        ;;
esac
EOF

chmod +x test-aptly.sh

# Verify installations
echo "🔍 Verifying installations..."
echo "  ✓ Ansible version: $(ansible --version | head -1)"
echo "  ✓ Git version: $(git --version)"

echo ""
echo "✅ ansible-role-aptly development environment setup complete!"
echo ""
echo "🎯 Quick start commands:"
echo "  • Deploy Aptly: ./test-aptly.sh deploy"
echo "  • Test API: ./test-aptly.sh test"
echo "  • Check containers: ./test-aptly.sh check"
echo "  • Manual deploy: ansible-playbook -i tests/inventory tests/test-multicontainer.yml"
echo ""
echo "📡 The Aptly API will be available on port 8080 when the role runs" 
