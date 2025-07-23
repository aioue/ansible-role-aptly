## aptly

* Installs the [aptly](http://www.aptly.info/) repository manager and enables the [REST API](http://www.aptly.info/doc/api/)

* Includes [test tasks](https://github.com/aioue/ansible-role-aptly/blob/master/tasks/test.yml) which perform common actions on the repository using curl requests

* Generates its own keypair used for signing

* Uses modern apt key management with `/etc/apt/keyrings/` instead of deprecated `apt-key`

* Supports current Ubuntu LTS versions: focal (20.04), jammy (22.04), noble (24.04)

* **Updated for modern Swagger API**: Uses the current [Swagger-documented API](https://www.aptly.info/doc/api/swagger/) instead of the deprecated legacy API

### Role Variables

* vars/main.yml: `aptly_key_email` email used to create your gpg key
* vars/main.yml: `aptly_company_name` name used to create your gpg key
* defaults/main.yml: `aptly_repositories` list of repositories to create with their distributions

### Setup clients to use the repo

```shell
# Download and install the public key
curl -fsSL https://www.aptly.info/pubkey.txt | sudo tee /etc/apt/keyrings/aptly.asc

# Add repository to sources list (replace {server_name} and {repository_name} with actual values)
echo 'deb [signed-by=/etc/apt/keyrings/aptly.asc] http://{server_name}/{repository_name} noble main' | sudo tee /etc/apt/sources.list.d/{repository_name}.list

# Update package lists
sudo apt update
```

### Upload a new package using the REST API

```shell
# Step 1: Upload package file to aptly
curl -X POST -F file=@<package_name>.deb http://localhost:8080/api/files/<upload_name>

# Step 2: Add uploaded file to repository
curl -X POST http://localhost:8080/api/repos/<repository_name>/file/<upload_name>

# Step 3: Publish/update the repository (only needed after adding packages)
curl -X PUT -H 'Content-Type: application/json' --data '{}' http://localhost:8080/api/publish/<repository_name>/<distribution>
```

### API Examples

```shell
# Check API version
curl http://localhost:8080/api/version

# List all repositories
curl http://localhost:8080/api/repos

# Create a new repository
curl -X POST -H 'Content-Type: application/json' \
  --data '{"Name": "my-repo", "Comment": "My packages", "DefaultDistribution": "noble", "DefaultComponent": "main"}' \
  http://localhost:8080/api/repos

# List packages in a repository
curl http://localhost:8080/api/repos/<repository_name>/packages

# Search for specific packages
curl 'http://localhost:8080/api/repos/<repository_name>/packages?q=<package_name>'
```

### API Documentation

This role now uses the modern [Swagger-documented API](https://www.aptly.info/doc/api/swagger/). The legacy API documentation at https://www.aptly.info/doc/api/ is no longer maintained.

For complete API reference, see: https://www.aptly.info/doc/api/swagger/

## License

MIT

## Author Information

* Tom Paine
* github | at | aioue.net
* https://github.com/aioue
