# Setting up your first dev cluster
This is a guide in how to get started with a local development cluster on your laptop.

To manage a cluster use a GNU/BusyBox/Linux, or possibly also a Mac or Window WSL laptop will do.

If you want to run the pods locally (acting as a host) then `podman` is mandatory and therefore a GNU/Linux OS is required.

A dev cluster works exactly as a production cluster, with the differences that:  

- There is only one host, your laptop.
- The `simplenetesd` Daemon process is run in foreground in user mode and not installed as a systemd unit.
- TLS certificates cannot be issued, since it's a closed system and public DNS is not applicable. Self signed certs can be used though.

If you only want to compile a single pod to use locally or want to learn more about Simplenetes Pods and the Pod compiler, we suggest reading [FIRSTPOD.md](FIRSTPOD.md).  

What we will be doing:  

1.  Installing the necessary programs
2.  Create the cluster project
3.  Add a pod to the cluster
4.  Compile the pod
5.  Sync the cluster locally
6.  Run the Daemon to manage the pods
7.  Update pods and re-sync the Cluster
8.  Add Proxy and Ingress
9.  Setup your development work flow

### 1. Installing all necessary programs
See [INSTALLING.md](INSTALLING.md) for instructions on installing `sns, `simplenetesd`, `podc` and `podman`.  

### 2. Setup a dev cluster
Let's create our first dev cluster inside a new directory and give it the id prefix `laptop-cluster`.

```sh
# First create a playground in ~/simplenetes
cd
mkdir simplenetes
cd simplenetes
```

Create the cluster:  
```sh
sns cluster create laptop-cluster
cd laptop-cluster
```

We now have three files in the cluster:  

- `cluster-id.txt` which contains the cluster ID provided to `init-host`.
    This ID is set on each host in the cluster so we can be sure operating only on correct hosts when managing the cluster.
    There is a random number suffixed to the given ID, which is a precaution to not mix up clusters.
- `cluster-vars.env` a key-value file which still is empty, but can have cluster-wide variables.
- `log.txt` which is a log file storing all operation done on the cluster.

You can change the cluster ID at this point directly in `cluster-id.txt`, but doing it later is not recommended.

Now, let's create a Host which is not a Virtual Machine but instead refers to our laptop, the option `--address=local` states that this is a local disk host.

The `--router-address=localIP:32767` option is needed when using a proxy for having pods communicate with each other and is required if using the Ingress and Proxy pods. Lookup your local IP address using `ifconfig` or `ip addr show` and set it as router address.

The `--dir-home` option dictates what directory is the `HOSTHOME` on the host. A relative directory will be considered relative to the users `$HOME`. We need to set this option when creating a local "cluster" so we safely can simluate running multiple hosts on the same laptop. When registering real hosts we don't need to specify this parameter.

```sh
cd laptop-cluster

sns host register laptop \
    --address=local \
    --dir-home=simplenetes/host-laptop \
    --router-address=192.168.1.198:32767
```

This will create a directory `laptop` inside your cluster repo which represents the Host within the cluster. Inside the directory there will be two files: 

- `host.env`, a key-value file containg the variables needed to connect to the host.
    The variable `HOSTHOME` dictates where on the Host files will get copied to when syncing the cluster repo with the remote cluster. For hosts which have HOST=local this is the directory on your laptop to where pods will get synced.
    This means that if simulating many Hosts on the same laptop they will need different HOSTHOME settings.
- `host.state`, a simple file which can contain the words `active`, `inactive` or `disabled`, and tells Simplenetes the state of this Host.
    A disabled host is ignored, an inactive host is still being managed by `sns` but will not receive ingress traffic, but can still be targed locally via the proxy.

Now we need to "init" this host, so it belong to our cluster. This will create the `HOSTHOME` directory `${HOME}/simplenetes/laptop` on your laptop.

Initing the host will also install any Docker image registry `config.json` file for that user as `~/.docker/config.json`. But doing this for local cluster will overwrite any existing such `config.json` file for the local user, so no point doing this when running locally. See [REGISTRY.md](REGISTRY.md) for more info on image registries.  
Note that Podman is compatible with Docker registries and images.

From inside the `laptop-cluster` dir, type:  
```sh
sns host init laptop
```

Look inside the `${HOME}/simplenetes/host-laptop` dir and you will see the file `cluster-id.txt`. This is the same file as in the cluster repo you created earlier.

Do not edit anything by hand inside the (pretend remote) `simplenetes/host-laptop` directory, all changes are always to be synced to here from the cluster project using `sns`.

Note: On a remote Host we would also want to install the Simplenetes Daemon `(simplenetesd)`. The Daemon is the process which manages pod lifecycles according to the state the pod is set to have. This process is show in the *PRODCLUSTER* section.


### 3. Add a pod to the cluster
When compiling new pod versions into the cluster, we need access to the Pod project and the pod specifications in there.

Pods are by default expected to be and cloned to the `_pods` dir inside your cluster repo.  

If you have another place for all your pods, you can set the `PODPATH` env variable to point there.

Note that a Pod is always attached to a specific Host, one or many. In Kubernetes in general pods are not bound to a specific Host, however in Simplenetes this is a design decision for Simplenetes that the operator attaches a pod to one or many specific Hosts.

From inside the `laptop-cluster` dir, type:  
```sh
sns host attach simplenetes_io@laptop --link=https://github.com/simplenetes-io/simplenetes_io.git
```

The git repo will get cloned into the `./_pods` directory.

Simplenetes will inform you about some variables defined in the `pod.env` file which you *might* want to redefine in the `cluster-vars.env` file. Note that variables in the `pod.env` file must be prefixed with the pod name when put in the `cluster-vars.env` file.

As: `allowHttp => simplenetes_io_allowHttp`.

For our development cluster it is desirable to allow unencrypted HTTP traffic through the ingress, so we add:  
```sh
cd laptop-cluster
echo "simplenetes_io_allowHttp=true" >>./cluster-vars.env
```

There is one special case of env variables and that is those who look like `${HOSTPORTAUTOxyz}`, those we will not define in `cluster-vars.env` because Simplenetes will assign those values depending on which host ports are already taken on each Host.

One can also auto assign cluster ports by using `${CLUSTERPORTAUTOxyz}`, then a cluster wide unique cluster ports is assigned.

All variables for pods which get defined in the cluster wide `cluster-vars.env` file must be prefixed with the pod name, this is to avoid clashes of common variable name, however variable names which are all `CAPS` are not to be prefixed and are treated as globals, this is so that some variables could be shared between pods.

Depending on the pod attached, Simplenetes could say that:  
```sh
[INFO]  This was the first attachment of this pod to this cluster, importing template configs from pod into cluster project.
```

Some background on this: Some pods have `configs`. Configs are directories which are deployed together with the pod and the pod's containers can mount them. Configs are very useful for container configurations which we want to update without deploying a new version.

Configs from a Pod are usually only imported once to the cluster (automatically when attaching), since they are treated as templates not as live configurations.
The configs can be edited after have been imported to the cluster project and they can be pushed out onto existing pod releases without the need for redeployments.

The `config` dir from the pod repo will have been copied into the cluster repo as `./_config/podname/config`.
These configs we now can tune and tailor to the needs of the cluster. Every time the pod is compiled the configs from the cluster will be copied to each pod release under each Host the pod is attached to.

Clusterports are used to map a containers port to a cluster-wide port so that other pods in the cluster can connect to it.
This means that every running pod which has defined the same cluster port will share traffic incoming on that port.

All replicas of a specific pod version share the same cluster ports, most often also pods of different version which are deployed simultaneously also share the same cluster ports. But the same `clusterPorts` are usually not shared between different types of pods.  

Cluster ports can be manually assigned in the range between `1024-29999 and 32768-65535` while ports `30000-32767` are reserved for host ports and the sns proxy.
Auto assigned cluster ports are assigned in the range of `61000-63999`.
Note that some official Simplenetes Pods have reserved cluster ports. The Letsencrypt Pod uses cluster port 64000, for instance.
Cluster ports and host ports are actual TCP listener sockets on the host.
Cluster ports from 64000 and above are not allowed to have ingress, meaning those cluster ports are protected against mistakenly opening them up publically to the public internet.

### 4. Compile the pod
When compiling an attached pod it is always required that the pod dir is a git repo.
This is because Simplenetes is very keen on versioning everything that happens in the cluster, both for traceability but also for options to rollback entire deployments.

From inside the `laptop-cluster` dir, type:  
```sh
sns pod compile simplenetes_io
```

At this point you can see in `laptop-cluster/pods/simplenetes_io/release/1.1.12/` that we have the compiled `pod`, the `pod.state` which dictates what state the pod should be in and potentially the `config` dir, which holds all configs.

Note that the `1.1.12` is taken from the `podVersion` in the `pod.yaml` file.

### 5. Sync the cluster locally
After we have updated a cluster repo with new pod release (or updated configs for an existing release) we can sync the cluster repo to the Cluster of Hosts.

This is done in the same way regardless if your cluster is your laptop or if it is a remote Cluster of many Virtual Machines.

Simplenetes is very strict about the cluster repo is committed before syncing, so that traceability and rollbacks are possible.

From inside the `laptop-cluster` dir, type:  
```sh
git add . && git commit -m "First sync"
sns cluster sync
```

Now, look inside the local `HOSTHOME` to see the files have been synced there:  
```sh
cd ${HOME}/simplenetes/host-laptop
ls -R
```

You will now see another file there: `commit-chain.txt`, this file contains all git commit hashes all the way back to the initial commit, it serves as a way to manage the scenario when the cluster is being synced from multiple sources at the same time so that an unintentional rollback is not performed.

Also when syncing, a `lock-token` file is temporarily placed in the directory to make sure no concurrent syncing is done.

### 6. Run the Daemon to manage the pods
In a real Cluster the Daemon will be running and would by now have picked up the changes to the Host and managed the effected pods.

Since we are running this on the laptop in dev mode, we won't install the Daemon into systemd (although you could), we will just start it manually instead.

Start the Daemon in the foreground to manage the pods.
```sh
cd ${HOME}/simplenetes/host-laptop
simplenetesd .
```

Start the daemon as `root` or with `sudo` if you want proper ramdisks to be created, else fake ramdisks on disk are created instead.

Note: Do not start the daemon as root without any arguments because then it runs as if a system deamon and it will search all `/home` for cluster projects.

The Daemon should now be running in the foreground and it will react on any changes to the pods or their configs whenever we re-sync the cluster.

Check the status of the pod:  
```sh
cd laptop-cluster
sns pod ps simplenetes_io
```

If all is good you will see a row as: `ports: 192.168.1.198:30000:80`.  

This port mapping is what the proxy will connected to, but we will try to curl directly against it just to see that the pod is alive. We need to add `--haproxy-protocol` to curl because nginx is expecting the proxy protocol.  

```sh
curl 192.168.1.198:30000 --haproxy-protocol
```

### 7. Update pods and re-sync to the cluster
Working with a dev-cluster you will either have the pods in `devmode=true` or not. Using devmode is typical when developing with single standalone pods which mount files
directly from disk instead of having images built for them, and when running your local dev-cluster you can choose to either simulate the full deal of building images for each
pod update or having one or many pods in devmode and then not needing to build images for each iteration.

To put the pod in your dev-cluster to development mode set `simplenetes_io_devmode=true` in the `cluster-vars.env` file prior to compiling the pod and syncing the cluster. Even though pods are synced to `host-laptop` the pod will still correctly mount the disk since paths become absolute when compiling.

If only configs of the pod has been updated, then it can be enough to update the configs of an already released pod.

The process of updating and pushing out new configs it simple:  
```sh
# Edit config files in ./laptop-cluster/_config/POD/CONFIG/
sns pod updateconfig POD
git add . && git commit -m "Update"
sns cluster sync
```

To release new version of our pod:  

Pull fresh the updated pod repo, compile it and sync to the cluster:  

```sh
cd laptop-cluster/_pods/simplenetes_io
git pull
```

If we now have a new version of the pod (as stated in the pod.yaml file `podVersion`), we can compile and release it.  

```sh
cd laptop-cluster
sns pod compile simplenetes_io
git add . && git commit -m "Update"
sns cluster sync
```

Check the current releases and their states:  
```sh
sns pod state simplenetes_io
```

Alright, now you have two versions of the same pod running. Both these pods will be sharing any incoming traffic from the cluster since they use the same ingress rules (but we still haven't added the proxy or the ingress pod, so there is no incoming traffic in that sense).

If we are happy with our new release, we can then retire the previous version. In this case we *must* provide the pod version we want to retire, since the default is to operate on the latest release if no version is given.

```sh
cd laptop-cluster
sns pod state simplenetes_io:1.1.12 -s removed
```

We need to commit our changes before we sync:  
```sh
cd laptop-cluster
git add .
git commit -m "Retire old version"

# Let's sync
sns cluster sync
```

You should now be able to see that the first pod is not responding on requests anymore.

Note that Simplenetes does also support transactional ways of doing rolling releases so we don't have to deal with all the details each time:  

```sh
sns pod release simplenetes_io
```

However, the release process expects the ingress pod to be present to work since it also regenerates the ingress config.

### 8. Add Proxy and Ingress
To be able to reach our pod as it was exposed to the internet we need to add the Proxy pod and the Ingress pod.

A special thing about the Ingress pod is that it most often binds to the ports 80 and 443 on the host but ports below 1024 are root only, this requires that the system is properly setup to allow for non-root users to bind to ports as low as 80 for the Ingress to work. `sns` sets this up automatically on hosts, but you will need to manually fix this on your laptop.

Find these details in the (INSTALLING.md)[INSTALLING.md] instructions.

In a proper cluster we would attach the Ingress pod to the hosts which are exposed to the internet and have DNS pointed to them, but now we attached it to our single pretend host.

```sh
cd laptop-cluster
sns host attach ingress@laptop --link=https://github.com/simplenetes-io/ingress
```

The config templates in the pod should have been automatically copied to the cluster project.

Let's generate the haproxy ingress configuration for this cluster:  
```sh
cd laptop-cluster
sns cluster geningress
```

You can inspect the generated `haproxy.cfg` if you are curious, it is inside `\_config/ingress/conf`.  

```sh
cd laptop-cluster
sns pod compile ingress
```

When we add some other pod, or update any pods ingress we need to again run `sns cluster geningress` and then `sns pod updateconfig ingress`, `git commit..`, `sns cluster sync`, following the pattern of updating configs for existing pods, so that the ingress (haproxy) gets the new config and re-reads it when synced to cluster.

This and some more is however conveniently packaged as `sns pod release <podname>`.

The Ingress pod will proxy traffic from the public internet to the pods within the cluster who match the ingress rules via the Proxy pod.

The Ingress pod will also (optionally) terminate TLS traffic.

When the Ingress pod has matched rules and optionally terminated TLS, it will route the traffic to the right Pod by connecting to the local Proxy pod on one of the listening ports we call _ClusterPort_.

The cluster port number is configured in the Ingress config and found by matching the rules of incoming traffic.

This configuration comes from the `pod.yaml` files when configuring for `ingress` and defining `clusterPort` or having it automatically assigned.

The Proxy pod runs on each host and knows the addresses to all other hosts in the cluster.
When a Pod (be it Ingress pod or any other pod) connects to a cluster port the proxy is listening to then the Proxy will try connecting to each Proxy on every other host on the reserved proxy port, with the hope that the remote proxy can tunnel the connection to a local pod's bound host port. See (COMPONENTS.md)[COMPONENTS.md] for more details.

Note that the Proxy pod is a "special" pod because it runs no containers, but instead is a native executable. However since it adheres to the Pod API it is still treated and managed as a Pod.

The Proxy pod should be attached to every Host in the Cluster, in our case it is only `laptop`.

```sh
cd laptop-cluster
sns host attach proxy@laptop --link=https://github.com/simplenetes-io/proxy
```

```sh
cd laptop-cluster
sns pod compile proxy
```

We need to commit our changes before we sync:  
```sh
cd laptop-cluster
git add . && commit -m "Add ingress and proxy"
# Let's sync
sns cluster sync
```

Now let's test to access the pods through the Ingress:  
```
curl 192.168.1.198/ -H "Host: simplenetes.io"
```

### 9. Setup your development work flow
Now that we have the local laptop-cluster setup, we can simulate all the pods and as they are communicating inside the cluster, locally.

See [WORKFLOW](WORKFLOW.md) for instructions.
