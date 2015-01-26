# Dynamic Ambassador

Dynamic [ambassador pattern](https://docs.docker.com/articles/ambassador_pattern_linking/) based on etcd,
confd, docker-gen and haproxy. This ambassador can be run on a single host but it' designed to be run on
a Docker cluster (like [CoreOS](https://coreos.com/) or [Docker Swarm](https://github.com/docker/swarm))

## Features

- Automated the registration of services and apps running on a Docker host
- Automated the redirection of requests to the service or the app on the true Docker host

This ambassador distinct two kind of container. **App** and **Service** container:

An **app** is an HTTP app accessed with a specific domain name.
It could be a REST API, a web server, etc. Any app relying on HTTP.

A **service** is a TCP service listening on a specific port.
It could be a database, a queuing service, etc. Any TCP app listening on a dedicated PORT with a custom protocol.

This distinction is important, because the mechanism used to proxy requests depends on it.
In a case it is a HTTP proxy, in the other it is a TCP load balancer.

## Usage

Before using this ambassador you need to have a running etcd service. If you don't use a CoreOS cluster you can create an etcd container like this:

```bash
docker run --rm -it -p 4001:4001 -p 7001:7001 microbox/etcd -name=test -addr=172.17.42.1:4001
```

See [here](https://github.com/coreos/etcd/blob/master/Documentation/clustering.md) how to set up a multi-machine cluster.

Start the ambassador container making sure:

- to expose port 80 on the host machine
- to configure the etcd host
- to configure the host IP


```bash
docker run --rm --name dynamic-ambassador -h dynamic-ambassador-1 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -e ETCD_HOST=${COREOS_PRIVATE_IPV4}:4001 \
  -e HOST_IP=${COREOS_PRIVATE_IPV4} \
  -p 80:80 \
  ncarlier/dynamic-ambassador
```

On a single host you can also use `make run` to start the container.
With CoreOS you can use the provided unit file:

```bash
fleetctl start ambassador@{1..3}.service
```

Once yours ambassador running you can start yours **apps** and **services**.


`dynamic ambassador` used environment variables into the container to configure **apps** and **services**:
An **app** is registered if the container has a **DOMAIN_NAME** environment variable.
A **service** is registered if the container has a **SERVICE_PORT** environment variable.

> Note: The container **must** also publish a port to be registered by the ambassador

### Sample

Run a MySQL database service:

```bash
docker run -d --name some-mysql \
  -e MYSQL_ROOT_PASSWORD=mysecretpassword \
  -e SERVICE_PORT=3306 \
  -P \
  mysql
```

Run a Wordpress app (not necessary on the same host):

```bash
docker run -d --name some-wordpress \
  --link dynamic-ambassador:mysql \
  -e DOMAIN_NAME=blog.domain.com \
  -e WORDPRESS_DB_PASSWORD=mysecretpassword \
  -e WORDPRESS_DB_HOST='mysql' \
  wordpress
```

Acces the Wordpress app (from any host):

```bash
curl -H "Host: blog.domain.com" 172.17.42.1
```

## Under the hood

The registration process is done by setting keys into etcd.
An app is registered like this:

```
/apps/<domaine_name>/<id>/<ip>:<pub-port>
```

  - *domain_name* is the domain name gotten from the environment variable
  - *id* is the container id
  - *ip* is the host IP
  - *pub-port* is the published port

A service is registered like this:

```
/services/<name>/<port>/<id>/<ip>:<pub-port>
```

  - *name* is the container name
  - *port* the service port
  - *id* is the container id
  - *ip* is the host IP
  - *pub-port* is the published port

Then the ambassador used `confd` for watching those keys and finally built the `HAProxy` configuration.
The apps keys are used to create a http reverse proxy configuration.
And the services keys are used to create a tcp load balancer.

