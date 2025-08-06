#!/bin/bash

# Aptly Testing Script for Docker Compose Environment
# Provides easy CLI commands to test aptly functionality

set -e

APTLY_SERVER_IP="172.20.0.10"
APTLY_API_PORT="8080"
API_BASE="http://${APTLY_SERVER_IP}:${APTLY_API_PORT}/api"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}🧪 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to check if containers are running
check_containers() {
    print_header "Checking container status..."
    
    if ! docker ps | grep -q aptly-server; then
        print_error "aptly-server container is not running"
        echo "Run: docker compose up -d"
        exit 1
    fi
    
    if ! docker ps | grep -q aptly-client; then
        print_error "aptly-client container is not running"
        echo "Run: docker compose up -d"
        exit 1
    fi
    
    print_success "Both containers are running"
}

# Function to test API connectivity
test_api() {
    print_header "Testing API connectivity..."
    
    if curl -s -f "${API_BASE}/version" > /dev/null; then
        VERSION=$(curl -s "${API_BASE}/version" | python3 -c "import sys, json; print(json.load(sys.stdin)['Version'])")
        print_success "API is accessible - Version: $VERSION"
    else
        print_error "API is not accessible at ${API_BASE}"
        return 1
    fi
}

# Function to list repositories
list_repos() {
    print_header "Listing repositories..."
    
    REPOS=$(curl -s "${API_BASE}/repos" | python3 -c "
import sys, json
data = json.load(sys.stdin)
if data:
    for repo in data:
        print(f\"  📦 {repo['Name']} - {repo['Comment']}\")
else:
    print('  No repositories found')
")
    echo "$REPOS"
}

# Function to list published repositories
list_published() {
    print_header "Listing published repositories..."
    
    PUBLISHED=$(curl -s "${API_BASE}/publish" | python3 -c "
import sys, json
data = json.load(sys.stdin)
if data:
    for pub in data:
        print(f\"  📢 {pub['Prefix']} - Distribution: {pub['Distribution']}\")
else:
    print('  No published repositories found')
")
    echo "$PUBLISHED"
}

# Function to show packages in a repository
show_packages() {
    local repo_name=${1:-testcompany-dev}
    print_header "Showing packages in repository: $repo_name"
    
    PACKAGES=$(curl -s "${API_BASE}/repos/${repo_name}/packages" | python3 -c "
import sys, json
data = json.load(sys.stdin)
if data:
    print(f'  Found {len(data)} packages:')
    for pkg in data[:10]:  # Show first 10 packages
        print(f\"    📋 {pkg}\")
    if len(data) > 10:
        print(f\"    ... and {len(data) - 10} more\")
else:
    print('  No packages found in repository')
" 2>/dev/null || echo "  Repository not found or empty")
}

# Function to test from client container
test_from_client() {
    print_header "Testing from client container..."
    
    docker exec aptly-client bash -c "
    echo '🔍 Testing API access from client:'
    if curl -s -f http://172.20.0.10:8080/api/version > /dev/null; then
        echo '✅ API accessible from client'
        VERSION=\$(curl -s http://172.20.0.10:8080/api/version | python3 -c \"import sys, json; print(json.load(sys.stdin)['Version'])\")
        echo \"📊 Aptly Version: \$VERSION\"
    else
        echo '❌ API not accessible from client'
    fi
    
    echo ''
    echo '🌐 Network connectivity:'
    ping -c 3 172.20.0.10 | tail -1
    "
}

# Function to run full test suite
run_full_tests() {
    print_header "Running full test suite with Ansible..."
    
    if [ -f "tests/test-client-functionality.yml" ]; then
        echo "Running comprehensive Ansible tests..."
        ansible-playbook -i tests/inventory tests/test-client-functionality.yml -v
    else
        print_warning "Comprehensive test playbook not found, running basic tests..."
        ansible-playbook -i tests/inventory tests/test-multicontainer.yml -v
    fi
}

# Function to deploy aptly role
deploy_aptly() {
    print_header "Deploying Aptly role to server..."
    
    echo "This will install and configure Aptly on the server container..."
    read -p "Continue? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [ -f "tests/test-multicontainer.yml" ]; then
            ansible-playbook -i tests/inventory tests/test-multicontainer.yml -v --tags "deploy" || \
            ansible-playbook -i tests/inventory tests/test-multicontainer.yml -v
        else
            print_error "Test playbook not found. Run setup first."
        fi
    fi
}

# Function to show container logs
show_logs() {
    local container=${1:-aptly-server}
    print_header "Showing logs for container: $container"
    
    docker logs --tail=50 "$container"
}

# Function to enter container shell
enter_container() {
    local container=${1:-aptly-server}
    print_header "Entering $container container..."
    
    docker exec -it "$container" bash
}

# Function to cleanup
cleanup() {
    print_header "Cleaning up test environment..."
    
    read -p "This will stop and remove containers. Continue? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker compose down -v
        print_success "Cleanup completed"
    fi
}

# Function to show help
show_help() {
    echo "🧪 Aptly Testing Script"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  status      - Check container and API status"
    echo "  deploy      - Deploy Aptly role to server"
    echo "  test        - Run full test suite with Ansible"
    echo "  test-api    - Test API connectivity"
    echo "  test-client - Test from client container"
    echo "  repos       - List repositories"
    echo "  published   - List published repositories"
    echo "  packages    - Show packages in repository [repo-name]"
    echo "  logs        - Show container logs [container-name]"
    echo "  shell       - Enter container shell [container-name]"
    echo "  cleanup     - Stop and remove containers"
    echo ""
    echo "Examples:"
    echo "  $0 status                    # Check everything is running"
    echo "  $0 deploy                    # Install Aptly"
    echo "  $0 test                      # Run comprehensive tests"
    echo "  $0 packages testcompany-dev  # Show packages in specific repo"
    echo "  $0 shell aptly-client        # Enter client container"
}

# Main script logic
case "${1:-status}" in
    "status")
        check_containers
        test_api
        ;;
    "deploy")
        check_containers
        deploy_aptly
        ;;
    "test")
        check_containers
        run_full_tests
        ;;
    "test-api")
        test_api
        ;;
    "test-client")
        check_containers
        test_from_client
        ;;
    "repos")
        list_repos
        ;;
    "published")
        list_published
        ;;
    "packages")
        show_packages "$2"
        ;;
    "logs")
        show_logs "$2"
        ;;
    "shell")
        enter_container "$2"
        ;;
    "cleanup")
        cleanup
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        echo "Unknown command: $1"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac 
