aptly
=====

Installs the [aptly](http://www.aptly.info/) respository manager and enables the REST API.

Includes test tasks which perform common actions on the repository using curl requests.

Role Variables
--------------

* vars/main.yml: `aptly_key_email` email used create your gpg key
* vars/main.yml: `aptly_company_name` name used to create your gpg key

### Setup clients to use the repo

```shell
apt-key add <generated public key on server>
echo 'deb http://<server_name>/<respository_name> trusty main' > /etc/apt/sources.list.d/<respository_name>.list
```

### Upload a new package using the REST API

```shell
curl -v -X POST -F file=@<package_name>.deb http://localhost:8080/api/files/<package_name>
curl -v -X POST http://localhost:8080/api/repos/<repository_name>/file/<package_name>
curl -v -X PUT -H 'Content-Type: application/json' --data '{}' http://localhost:8080/api/publish/<repository_name>/trusty
```

## License

MIT

## Author Information

* Tom Paine
* github | at | aioue.net
* https://github.com/aioue
