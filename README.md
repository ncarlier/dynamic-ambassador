haproxy combined with confd for HTTP load balancing

Start the container making sure to expose port 80 on the host machine

    docker run -e ETCD_HOST=172.17.42.1:4001 -p 80:80 ncarlier/haproxy-confd

Create at least one service inside of '/domains'

    etcdctl set "/domains/myapp" "myapp.com"
