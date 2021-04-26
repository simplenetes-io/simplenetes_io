# Attach pods and run then in your production Cluster

In this section, we'll cover how to add some initial Pods to a newly provisioned Cluster. After completing the steps, everything is expected to be up and running.
> Note: this section depends on the Cluster being already provisioned, as covered on [previous sections](DEVCLUSTER.md). If you haven't, see the [Setting up your first dev cluster](DEVCLUSTER.md) section for details on how to create the Cluster.


Attach Pods:  
```sh
cd prod-cluster
sns host attach ingress@loadbalancer1 --link=https://github.com/simplenetes-io/ingress
sns host attach proxy@loadbalancer1 --link=https://github.com/simplenetes-io/proxy
sns host attach proxy@worker1 --link=https://github.com/simplenetes-io/proxy
sns host attach letsencrypt@worker1 --link=https://github.com/simplenetes-io/letsencrypt.git
sns host attach simplenetes_io@worker1 --link=https://github.com/simplenetes-io/simplenetes_io.git
```

Configure the Cluster:  
```sh
cd prod-cluster

# Have the Ingress fetch certificates from the Let's Encrypt Pod:
echo "ingress_useFetcher=true" >>cluster-vars.env

# Allow HTTP ingress traffic for the simplenetes_io pod.
echo "simplenetes_io_allowHttp=true" >>cluster-vars.env
```

Compile all Pods:  
```sh
sns pod compile simplenetes_io
sns pod compile proxy
sns pod compile letsencrypt
sns pod compile ingress
```

Generate Ingress settings:  
```sh
sns cluster geningress
sns pod updateconfig ingress
```

Synchronize the Cluster:  
```sh
git add . && git commit -m "Initial"
sns cluster sync
```

## Releasing new versions of Pods
Whenever the _pod.yaml_ file changes and the `podVersion` value is modified, flagging it as an update, it is possible to release a new version of that Pod with a single command:
```sh
sns pod release <NAME>
```

The commands involved in the `release` operation can also be manually performed, but it is much more cumbersome. For completion, the commands are:
```sh
sns pod compile NAME
sns cluster geningress
sns pod updateconfig ingress
git add . && git commit -m "Update"
sns cluster sync
# Both the old and the new version of the pod are expected to be running at the same time and sharing traffic
sns pod ls NAME
sns pod state NAME:oldversion -s removed
sns cluster geningress
sns pod updateconfig ingress
git add . && git commit -m "Update"
sns cluster sync
# The old version is now removed and the ingress updated.
```

## Let's Encrypt certificates
Manually edit the file `./prod-cluster/_config/letsencrypt/certs_list/certs.txt` and add all domains which you need certificates for.
Then, the Pod config needs to be updated:  
```sh
sns pod updateconfig letsencrypt
git add . && git commit -m "Configure certs"
sns cluster sync
```

## Cheatsheet and Troubleshooting
The following commands are helpful:  
```sh
sns pod info NAME
sns pod ps NAME
sns pod logs NAME
sns pod state NAME
sns pod ls
sns pod shell NAME [container]
sns host shell NAME
```
