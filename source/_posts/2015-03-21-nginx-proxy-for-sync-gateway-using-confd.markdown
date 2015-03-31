---
layout: post
title: "Nginx proxy for Sync Gateway using Confd"
date: 2015-03-21 15:25
comments: true
categories: docker coreos nginx
---

This will walk you through setting up Sync Gateway behind nginx.  The nginx conf will be auto generated based on Sync Gateway status.

### Launch CoreOS instances on EC2

[<img src="https://s3.amazonaws.com/cloudformation-examples/cloudformation-launch-stack.png">](https://console.aws.amazon.com/cloudformation/home?region=us-east-1#cstack=sn%7ECouchbase-CoreOS%7Cturl%7Ehttp://tleyden-misc.s3.amazonaws.com/couchbase-coreos/sync_gateway.template)

Recommended values:

* **ClusterSize**: 3 nodes (default)
* **Discovery URL**:  as it says, you need to grab a new token from https://discovery.etcd.io/new and paste it in the box.
* **KeyPair**: the name of the AWS keypair you want to use.  If you haven't already, you'll want to upload your local ssh key into AWS and create a named keypair.

### Wait until instances are up

![screenshot](http://tleyden-misc.s3.amazonaws.com/blog_images/cloud-formation-create-complete.png)

### ssh into a CoreOS instance

Go to the AWS console under EC2 instances and find the public ip of one of your newly launched CoreOS instances.

![screenshot](http://tleyden-misc.s3.amazonaws.com/blog_images/ec2-instances-coreos.png)  

Choose any one of them (it doesn't matter which), and ssh into it as the **core** user with the cert provided in the previous step:

```
$ ssh -i aws.cer -A core@ec2-54-83-80-161.compute-1.amazonaws.com
```

## Spin up Sync Gateway containers

```
$ etcdctl set /couchbase.com/enable-code-refresh true
$ sudo docker run --net=host tleyden5iwx/couchbase-cluster-go update-wrapper sync-gw-cluster launch-sgw --num-nodes=2 --config-url=http://git.io/hFwa --in-memory-db
```

## Verify etcd entries

```
$ etcdctl ls --recursive /
...
/couchbase.com/sync-gw-node-state
/couchbase.com/sync-gw-node-state/10.169.70.114
/couchbase.com/sync-gw-node-state/10.231.220.110
```

## Create data volume container

```
$ wget https://raw.githubusercontent.com/lordelph/confd-demo/master/confdata.service
$ fleetctl start confdata.service
```

## Launch sync-gateway-nginx-confd.service

```
$ wget https://raw.githubusercontent.com/lordelph/confd-demo/master/confd.service
$ sed -i -e 's/lordelph\/confd-demo/tleyden5iwx\/sync-gateway-nginx-confd/' confd.service
$ fleetctl start confd.service
```

## Launch nginx service

```
$ wget https://raw.githubusercontent.com/lordelph/confd-demo/master/nginx.service
$ fleetctl start nginx.service
```

## Verify 

Try a basic http get.

```
$ nginx_ip=`fleetctl list-units | grep -i nginx | awk '{print $2}' | awk -F/ '{print $2}'`
$ curl $nginx_ip
{"couchdb":"Welcome","vendor":{"name":"Couchbase Sync Gateway","version":1},"version":"Couchbase Sync Gateway/master(a47a17f)"}
```

Add '-v' flag to see which Sync Gateway server is servicing the request

```
$ curl -v $nginx_ip
...
X-Handler: 10.231.220.110:4984
...
```

If you repeat that a few more times, you should see different ip addresses for the handler.

**Take a sync gateway out of rotation**

```
$ fleetctl stop sync_gw_node@1.service sync_gw_sidekick@1.service
```

Now try hitting nginx again, and should not see the Sync Gw that you just shutdown as a handler.

```
$ curl -v $nginx_ip
...
X-Handler: 10.231.220.114:4984
...
```

**Put sync gateway back into rotation**

```
$ fleetctl start sync_gw_node@1.service sync_gw_sidekick@1.service
```

Now try hitting nginx again, and should again see the Sync Gw that you just restarted as being a handler.

```
$ curl -v $nginx_ip
...
X-Handler: 10.231.220.110:4984
...
```


## References

* http://blog.dixo.net/2015/02/load-balancing-with-coreos