# Aptly Role Testing Environment

This repository includes a Docker Compose testing environment with two Ubuntu Noble containers for testing the Aptly role functionality.

## Quick Start

### 1. Start the Environment

The devcontainer should automatically start both containers when you "Reopen in Container". 

Alternatively, you can manually start with:
```bash
docker compose up -d
```

### 2. Run Tests

Use the provided test script:

```bash
# Check container status
./test-aptly.sh check

# Deploy Aptly to server
./test-aptly.sh deploy

# Test API connectivity
./test-aptly.sh test
```

### 3. Manual Testing

```bash
# Deploy role to server container
ansible-playbook -i tests/inventory tests/test-multicontainer.yml
```

## Architecture

- **aptly-server** (172.20.0.10): Ubuntu Noble with systemd for running Aptly
- **aptly-client** (172.20.0.20): Ubuntu Noble for testing client functionality

## API Access

Once deployed:
- **From host**: http://localhost:8080/api
- **From containers**: http://172.20.0.10:8080/api

## Container Access

```bash
# Enter server container
docker exec -it aptly-server bash

# Enter client container
docker exec -it aptly-client bash
```

## Troubleshooting

If containers aren't starting:
```bash
docker compose down
docker compose up -d
```

If API isn't accessible, deploy the role first:
```bash
./test-aptly.sh deploy
``` 
