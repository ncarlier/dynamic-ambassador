# Dynamic Ambassador

Dynamic ambassador pattern based on etcd, confd and haproxy.

Start the container making sure to expose port 80 on the host machine

    docker run -e ETCD_HOST=172.17.42.1:4001 -p 80:80 ncarlier/haproxy-confd

`dynamic-ambassador` is made to be run with [dynamic-registrator](https://github.com/ncarlier/dynamic-registrator)
