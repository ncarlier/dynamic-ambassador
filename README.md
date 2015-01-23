# Dynamic Ambassador

Dynamic [ambassador pattern](https://docs.docker.com/articles/ambassador_pattern_linking/) based on etcd,
confd, docker-gen and haproxy. This ambassador can be run on a single host but it' designed to be run on
a Docker cluster (like [CoreOS](https://coreos.com/) or [Docker Swarm](https://github.com/docker/swarm))

## Features

- Automated the registration of services and applications running on a Docker host
- Automated the redirection of requests to the service or the application on the true Docker host

## Usage

Before using this ambassador you need to have a running etcd service. If you don't use a CoreOS cluster you can create an etcd container like this:

    $ docker run --rm -it -p 4001:4001 -p 7001:7001 microbox/etcd -name=test -addr=172.17.42.1:4001

See [here](https://github.com/coreos/etcd/blob/master/Documentation/clustering.md) how to set up a multi-machine cluster.

Start the ambassador container making sure:

- to expose port 80 on the host machine
- to configure the etcd host
- to configure the host IP

    $docker run --rm --name dynamic-ambassador -h dynamic-ambassador-1 \
      -v /var/run/docker.sock:/var/run/docker.sock \
      -e ETCD_HOST=${COREOS_PRIVATE_IPV4}:4001 \
      -e HOST_IP=${COREOS_PRIVATE_IPV4} \
      -p 80:80 \
      ncarlier/dynamic-ambassador

On a single host you can also use `make run` to start the container.
With CoreOS you can use the provided unit file:

  fleetctl start ambassador@{1..3}.service

Once yours ambassador running you can start yours **applications** and **services**.
An **application** is an HTTP application accessed with a specific domain name. A **service** is a TCP service listening on a specific port.


`dynamic ambassador` used environment variables into the container to configure **applications** and **services**:
An **application** is registered if the container has a **DOMAIN_NAME** environment variable.
A **service** is registered if the container has a **SERVICE_PORT** environment variable.

> Note: The container **must** also publish a port to be registered by the ambassador

### Sample

Run a MySQL database service:

  $ docker run -d --name some-mysql \
    -e MYSQL_ROOT_PASSWORD=mysecretpassword \
    -e SERVICE_PORT=3306 \
    -P \
    mysql

Run a Wordpress application (not necessary on the same host):

  $ docker run -d --name some-wordpress \
    --link dynamic-ambassador:mysql \
    -e DOMAIN_NAME=blog.domain.com \
    -e WORDPRESS_DB_PASSWORD=mysecretpassword \
    -e WORDPRESS_DB_HOST='mysql' \
    wordpress

Acces the Wordpress application (from any host):

  curl -H "Host: blog.domain.com" 172.17.42.1

## Under the hood

The registration process is done by setting keys into etcd.
An application is registered like this:

    /applications/<domaine_name>/<id>/<ip>:<pub-port>

  - *domain_name* is the domain name gotten from the environment variable
  - *id* is the container id
  - *ip* is the host IP
  - *pub-port* is the published port

A service is registered like this:

    /services/<name>/<port>/<id>/<ip>:<pub-port>

  - *name* is the container name
  - *port* the service port
  - *id* is the container id
  - *ip* is the host IP
  - *pub-port* is the published port

Then the ambassador used `confd` for watching those keys and finally built the `HAProxy` configuration.
The applications keys are used to create a http reverse proxy configuration.
And the services keys are used to create a tcp load balancer.

