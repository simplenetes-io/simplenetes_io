# Setting up your first dev cluster
This is a guide in how to get started with a local development cluster (_dev cluster_) on your laptop.

To manage a cluster, use _GNU/BusyBox/Linux_ (possibly _macOS_ or _Windows Subsystem for Linux_ will also do).

If you want to run the pods locally (acting as a host) then [`podman`](https://podman.io/) is mandatory and therefore a _GNU/Linux_ _OS_ is required.

A dev cluster works exactly as a production cluster, with the following differences:  

- There is only one host: either your laptop or personal computer.
- The `simplenetesd` Daemon process is run in foreground in user mode and it is not installed as a [_systemd_](https://www.freedesktop.org/wiki/Software/systemd/) unit.
- _TLS_ certificates cannot be issued, since it's a closed system and public _DNS_ is not applicable. Self-signed certificates can still be used, though.

If you only want to compile a single Pod to run locally or want to learn more about _Simplenetes_ Pods and the Pod compiler, we suggest focusing on understanding how to [Create your first Simplenetes Pod](FIRSTPOD.md).

Proceeding with this section, here's what we will be doing:  

1.  Installing the necessary programs;
2.  Creating the Cluster project;
3.  Adding a Pod to the Cluster;
4.  Compiling the Pod;
5.  Synchronizing the Cluster locally;
6.  Running the Daemon to manage the Pods;
7.  Updating Pods and re-syncing the Cluster;
8.  Adding Proxy and Ingress pods;
9.  Setting up a development workflow;

### Installing all necessary programs
Follow the instructions in [Installing Simplenetes](INSTALLING.md) section to set up and install `sns, `simplenetesd`, `podc` and `podman` programs.  

### Setup a dev cluster
Let's create our first dev cluster inside a new directory and give it the id prefix `laptop-cluster`.

```sh
# First create a playground in ~/simplenetes
cd
mkdir simplenetes
cd simplenetes
```

Create the Cluster:  
```sh
sns cluster create laptop-cluster
cd laptop-cluster
```

We now have three files in the cluster:  

- _cluster-id.txt_: contains the Cluster ID provided to `init-host`.
    This ID is set on each host in the Cluster so we can be sure about operating only on correct hosts when managing the Cluster.
    There is a random number suffixed to the given ID, which is a precaution to not mix up clusters.
- _cluster-vars.env_: a key-value configuration file, which still is empty, that serves to define Cluster-wide environment variables.
- _log.txt_: log file storing all operations done on the cluster.

You can change the Cluster ID at this point directly in _cluster-id.txt_.
> Note: changing the Cluster ID at a later point is not recommended.

Now, let's create a Host which is not a Virtual Machine, but refers to our laptop instead. The option `--address=local` states that this is a Host present in the local disk.

The `--router-address=localIP:32767` option is needed when using a Proxy for having Pods communicating with each other. It is required if using the Ingress and Proxy Pods. Lookup your local IP address using `ifconfig` or `ip addr show`, then set it as router address.

The `--dir-home` option dictates what directory is the `HOSTHOME` on the host. A relative directory will be considered relative to the users `$HOME` setting. We need to set this option when creating a "local cluster" so we safely can simulate running multiple Hosts on the same laptop. When registering real Hosts we don't need to specify this parameter.

```sh
cd laptop-cluster

sns host register laptop \
    --address=local \
    --dir-home=simplenetes/host-laptop \
    --router-address=192.168.1.198:32767
```

This will create a directory `laptop` inside your Cluster repo which represents the Host within the cluster. Inside the directory there will be two files: 

- _host.env_: a key-value configuration file containing the environment variables needed to connect to the host.
    The variable `HOSTHOME` dictates where the Host files will get copied to when syncing the Cluster repo with the remote Cluster. This is the directory on your laptop to where pods will get synced (only for hosts which have `HOST=local` set).
    This means that if simulating many Hosts on the same laptop they will need different `HOSTHOME` settings.
- _host.state_: a simple file which can contain the words such as: `active`, `inactive` or `disabled`. This tells _Simplenetes_ the state of this Host.
    While `disabled` hosts are ignored, an `inactive` host is still managed by `sns`, but it will not receive Ingress traffic. Inactive hosts can still be targeted locally via the Proxy.

Now we need to initialize this Host, so it joins our Cluster. This process will create the `HOSTHOME` directory at `${HOME}/simplenetes/laptop` on your laptop.

Initializing the Host will also install any [_Docker_](https://www.docker.com/) image registry configuration file for that user to _~/.docker/config.json_. 

> Note: this for local cluster will overwrite any existing such _config.json_ file for the local user, so no point doing this when running locally. See [Configuring image registries](REGISTRY.md) documentation for more info about it.  

> Note: [_Podman_](https://podman.io/) is compatible with _Docker_ registries and images.

From inside the _laptop-cluster_ directory, enter:  
```sh
sns host init laptop
```

Inspect the _${HOME}/simplenetes/host-laptop_ directory and you will see the file _cluster-id.txt_. This is the same file as in the Cluster repo created earlier. Changes to that file are always to be synced to that directory from the Cluster project using `sns`.

> Note: do not edit anything inside initialized Host directories.

> Note: on a remote Host we would also want to install the Simplenetes Daemon (`simplenetesd`). The Daemon is the process which manages Pod lifecycles according to their state. This process is shown in the [Production Cluster](PRODCLUSTER.md) section.


### Add a pod to the cluster
When compiling new Pod versions into the Cluster, we need access to the Pod project and the Pod specifications from there.

By default, Pods are expected to be cloned into the `_pods` directory inside your Cluster repo.  

If you have another favorite place to store all your Pods, you can set the `PODPATH` environment variable to point there.

> Note: a Pod is always attached to one or multiple specific Hosts. The general case in Kubernetes is often that pods are not bound to a specific Host. On the other hand, in Simplenetes this is a design decision so that the operator is able to attach a Pod to one or many specific Hosts.

From inside the _laptop-cluster_ dir, type:  
```sh
sns host attach simplenetes_io@laptop --link=https://github.com/simplenetes-io/simplenetes_io.git
```

The [_Git_](https://git-scm.com/) repo will get cloned into the `./_pods` directory.

During the process, _Simplenetes_ will inform you about some variables defined in the _pod.env_ file which you *might* want to redefine in the _cluster-vars.env_ file.
> Note: variables defined in the _pod.env_ file must be prefixed with the Pod name when referenced in the _cluster-vars.env_ file. Example for `allowHttp` Pod environment variable: `simplenetes_io_allowHttp`.

For our development cluster it is desirable to allow unencrypted _HTTP_ traffic through the Ingress, so we add that setting to the list of Cluster variable settings:  
```sh
cd laptop-cluster
echo "simplenetes_io_allowHttp=true" >>./cluster-vars.env
```

There is one special case of environment variables and that is those that look like `${HOSTPORTAUTOxyz}`. Those we will not be defined in _cluster-vars.env_ because _Simplenetes_ will automatically assign those depending on which Host ports are already taken on each Host.

It is possible to automatically assign Cluster ports by using `${CLUSTERPORTAUTOxyz}`. With that a Cluster-wide unique port is assigned.

All variables for Pods which get defined in the Cluster-wide _cluster-vars.env_ file must be prefixed with their respective Pod name. This serves to avoid clashes of common variable names. The exception to that are variable names which are `ALLCAPS`. The convention on global variables is so that some variables could be shared between pods.
> Note: `ALLCAPS` variable names are not to be prefixed because they are treated as globals.

Depending on the Pod attached, _Simplenetes_ could inform that:  
```sh
[INFO]  This was the first attachment of this pod to this cluster, importing template configs from pod into cluster project.
```

Some background on this: Some pods have _configs_. Configs are directories which are deployed together with the Pod and that Pod's containers can mount them. Configs are very useful for container configurations which we want to update without having to necessarily deploy a new version.

Configs from a Pod are usually only imported once to the Cluster (automatically done when attaching), since they are treated as templates instead of live configurations.
These configurations can be edited after being imported to the Cluster project. They can also be pushed out onto existing Pod releases without the need for redeployments.

The _config_ directory from the Pod repo in this case would have been copied into the cluster repo as `./_config/podname/config`.
These configs can now be tuned and tailored to satisfy the needs of the Cluster. Every time the Pod is compiled the configurations from the Cluster will be copied to each Pod release under each Host the Pod is attached to.

Cluster ports (`clusterPorts`) are used to map a containers port to a Cluster-wide port in a way that other Pods in the Cluster can connect to it.
This means that every running Pod which has defined the same Cluster port will share traffic incoming on that port.

All replicas of a specific Pod version share the same Cluster ports, most often also Pods of different version which are deployed simultaneously also share the same Cluster ports. Exact same `clusterPorts` are usually not shared between different types of Pods.  

Cluster ports can be manually assigned in the range between `1024-29999` and `32768-65535`. Ports `30000-32767` are reserved for Host ports and the `sns` Proxy.
Auto-assigned Cluster ports are assigned in the range of `61000-63999`.
Note that Pods provided by Simplenetes (official Pods) have reserved Cluster ports. The Let's Encrypt Pod uses Cluster port `64000`, for instance.

> Note: Cluster ports and Host ports are actual _TCP_ listener sockets on the host.

Cluster ports starting from `64000` and above are not allowed to have Ingress, meaning those Cluster ports are protected against human error, such as when erroneously opening them up publically to the public internet.

### Compile the pod
When compiling an attached Pod, it is always required that the referenced Pod directory is a _Git_ repository.
This is because _Simplenetes_ is very keen on versioning everything that happens in the Cluster, both for traceability as well as for providing the option to rollback entire deployments.

From inside the _laptop-cluster_ dir, type:  
```sh
sns pod compile simplenetes_io
```

At this point you can see in `laptop-cluster/pods/simplenetes_io/release/1.1.12/` that we have the compiled the following elements: the `pod`, the `pod.state` (which dictates what state the Pod should be in) and potentially the _config_ dir as well (the one which holds all configuration).

Note that the `1.1.12` is taken from the `podVersion` attributed in the `pod.yaml` file.

### Sync the cluster locally
After we have updated a Cluster repo with new Pod release (or updated configs for an existing release) we can sync the Cluster repo to the Cluster of Hosts.

This is done in the same way regardless if your Cluster is your laptop or if it is a remote Cluster composed of many Virtual Machines.

Simplenetes is very strict about the Cluster repo being committed before syncing, so that traceability and rollbacks are possible.

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

You will now see another file there: _commit-chain.txt_, this file contains all _Git_ commit hashes all the way back to the initial commit. The commit history serves as a way to manage the scenario when the Cluster is being synced from multiple sources at the same time so that an unintentional rollback is not performed.

Also when syncing, a _lock-token_ file is temporarily placed in the directory to make sure no concurrent syncing is done.

### Run the Daemon to manage the pods
In a real Cluster the Daemon will be running and would by now have picked up the changes to the Host and managed the affected pods.

Since we are running this on the laptop in dev mode, we won't install the Daemon into _systemd_, even though we could. For the purposes of demonstration, we will just start it manually instead.

Start the Daemon in the foreground to manage the Pods:
```sh
cd ${HOME}/simplenetes/host-laptop
simplenetesd .
```

Start the daemon as _root_ or with `sudo` if you want proper _ramdisks_ to be created. Otherwise, fake _ramdisks_ will be created on disk instead.

> Note: Do not start the daemon as root without any arguments because then it runs as if it was a system deamon and it will search all directories under _/home_ for Cluster projects.

The Daemon should now be running in the foreground and it will react on any changes to the Pods or their configs whenever we re-sync the Cluster.

Check the status of the Pod:  
```sh
cd laptop-cluster
sns pod ps simplenetes_io
```

If all is good you will see a row appear as follows:
```
ports: 192.168.1.198:30000:80
```

This port mapping is what the Proxy will connect to. Instead of sending a request to that reference, we will try to `curl` directly against it just to see that the pod is alive. In the following example, using `curl`, we add `--haproxy-protocol` option because [_NGINX_](https://www.nginx.com/) is expecting the proxy protocol to be present:  
```sh
curl 192.168.1.198:30000 --haproxy-protocol
```

### Update Pods and re-sync to the Cluster
While working with a development Cluster you will either have the Pods in `devmode=true` or not. Using `devmode` is typical when developing with single standalone Pods which mount files directly from disk instead of having images built for them. When running your local dev Cluster you can choose to either simulate the full deal of building images on every Pod update or having one or many pods in `devmode` and then not needing to build images for any iteration at all.

To put the Pod in your dev Cluster in development mode, set `simplenetes_io_devmode=true` in the _cluster-vars.env_ file prior to compiling the Pod. After that, sync the cluster. Even though Pods are synced to _host-laptop_, the Pod will still correctly mount the disk since relative paths are translated into absolute paths when compiling.

If only Pod configurations have been updated, then it can be enough to update the configs of an already released Pod.

The process of updating and pushing out new configs is simple:  
```sh
# Edit config files in ./laptop-cluster/_config/POD/CONFIG/
sns pod updateconfig POD
git add . && git commit -m "Update"
sns cluster sync
```

To release a new version of our Pod, first pull fresh the updated Pod repo, then compile and sync it to the cluster:  
```sh
cd laptop-cluster/_pods/simplenetes_io
git pull
```

We now have a new version of the Pod (as stated in the _pod.yaml_ file `podVersion`), so we can compile and release it:
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

Alright, now you have two versions of the same pod running. Both these pods will be sharing any incoming traffic from the cluster since they use the same Ingress rules. Reminder that we still haven't added the Proxy or the Ingress pod, so there is no incoming traffic in practice.

When we are happy with our new release, we can then retire the previous version. In this case we *must* provide the Pod version we want to retire.
```sh
cd laptop-cluster
sns pod state simplenetes_io:1.1.12 -s removed
```

Note: commands which take versions as parameters default to reference the latest version when no parameter is provided (implicit option).


We need to commit our changes before synchronizing:  
```sh
cd laptop-cluster
git add .
git commit -m "Retire old version"

# Let's sync
sns cluster sync
```

You should now be able to see that the first Pod is not responding on requests anymore.

Note that _Simplenetes_ also supports transactional ways of doing rolling releases so we don't have to deal with all the details each time:  

```sh
sns pod release simplenetes_io
```

> Note: the transactional release process expects the Ingress Pod to be present because the Ingress Pod becomes responsible for regenerating the Ingress config.


### Add Proxy and Ingress
In order to be able to reach our Pod as if it was exposed to the Internet we need to add the Proxy pod and the Ingress pod.

A special thing about the Ingress Pod is that it most often binds to ports `80` and `443` on the Host, but ports below `1024` require administrative rights in order to be managed by users. This requires that the system is properly set up to allow for non-root users to bind to ports as low as `80` for the Ingress to work. `sns` sets this up automatically on Hosts, as long as the requirements are met.

More details about initial setup can be found in the (Install instructions)[INSTALLING.md].

In a proper Cluster we would attach the Ingress Pod to the Hosts which are exposed to the Internet and have _DNS_ pointed to them. For this example we attached it to our single pretend Host.

```sh
cd laptop-cluster
sns host attach ingress@laptop --link=https://github.com/simplenetes-io/ingress
```

The config templates in the Pod should have been automatically copied to the Cluster project.

Let's generate the [_HAProxy_](http://www.haproxy.org/) Ingress configuration for this Cluster:  
```sh
cd laptop-cluster
sns cluster geningress
```

> Note: If you are curious about _HAProxy_ settings, you can inspect the generated _haproxy.cfg_ inside the `\_config/ingress/conf` directory.  

```sh
cd laptop-cluster
sns pod compile ingress
```

When we add some other Pod or update any Pods Ingress settings, we need to to repeat the `sns cluster geningress` command and then follow the pattern of updating configs for existing pods:
```
sns pod updateconfig ingress
git commit[...]
sns cluster sync
```
This is so that the Ingress gets the new config and re-reads it when synced to cluster.

This and some more is conveniently packaged in the form of a single command:
```
sns pod release <podname>
```

The Ingress pod will proxy traffic from the public Internet to the pods within the cluster that match the Ingress rules via the Proxy Pod.
As an option, the Ingress Pod will also terminate _TLS_ traffic.

When the Ingress Pod has matched rules and optionally terminated _TLS_, it will route the traffic to the right Pod by connecting to the local Proxy Pod on one of the listening ports. These listening ports are called _Cluster Ports_.

The cluster port number is configured in the Ingress config and found by matching the rules of incoming traffic.

This configuration comes from the _pod.yaml_ files when configuring for `ingress` and defining `clusterPort` or having it automatically assigned.

The Proxy Pod runs on each Host and it knows the addresses to all other Hosts in the cluster.
When a Pod, be it Ingress Pod or any other Pod, connects to a cluster port the proxy is listening to, then the Proxy will try connecting to each Proxy on every other Host on the reserved Proxy port, with the hope that the remote Proxy can match and tunnel the connection to a local pod's bound Host port. See [Components and Terminology](COMPONENTS.md) for more details.

> Note: the Proxy Pod is a "special" pod because it runs no containers. The Proxy Pod is a native executable. However, since it adheres to the Pod _API_ it is still treated and managed as a Pod.

The Proxy Pod is expected to be attached to every Host in the Cluster. In our example case, that is only `laptop`.

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

### Setup your development workflow
Now that we have the local, laptop-based, Cluster setup, we can simulate all the Pods and see how they are communicating inside the Cluster, all locally.


This concludes the basics of development mode. The [next section](PROVISIONING.md) introduces the topic of remote machines provisioning and production Clusters.
