# The Components and Terminology of Simplenetes

This section provides an architectural view of **Simplenetes**.

The goal for _Simplenetes_ is to be composed of as few moving parts as possible, while having a robust and easy to understand design. You will not find any usage of `iptables` nor any `etcd` cluster.

The parts are:

- Pods. Including:  
    - Ingress Pod
    - Proxy Pod
    - Let's Encrypt Pod
    - The Pod compiler (`podc`)
- Hosts
- Clusters and Cluster Projects (as [_Git_](https://git-scm.com/) repositories)
- The Proxy and clusterPorts
- Daemon (`simplenetesd`)
- The `sns` management tool

## Pods
A **Simplenetes** Pod is the same as a [_Kubernetes_](https://kubernetes.io/) Pod in the sense that it is defined as a set of one or many containers which are managed together and share the same network.

A _Simplenetes_ Pod is described in a single and simple [_YAML_](https://en.wikipedia.org/wiki/YAML) file format named _pod.yaml_. It is compiled into a standalone shell script which uses [`podman`](https://podman.io/) as container runtime.

The standalone shell script, named `pod`, can be run as is, either locally or managed by the _Simplenetes_ Daemon (`simplenetesd`) on a host.

The `pod` shell script uses `podman` to run containers, which is made for running containers as an unprivileged user (rootless). _Podman_ is compatible with [_Docker_](https://www.docker.com/).

### Special Pods
There are three special Pods in _Simplenetes_. Most often they are used in Clusters, but they do not have to be. The Pods are:  
- **Ingress Pod**: responsible for inbound traffic routing and [_TLS_](https://en.wikipedia.org/wiki/Transport_Layer_Security) termination coming from the Internet (using [_HAProxy_](http://www.haproxy.org/));   
- **Proxy Pod**: an internal traffic router allowing Pods to talk to other Pods on other hosts or on the same host within the internal network;  
- **Let's Encrypt Pod**: renews _SSL/TLS_ certificates for all domains and makes them available to the Ingress Pod using [Let's Encrypt](https://letsencrypt.org/).

Actually, _Simplenetes_ Pods do not have to be containers at all. A _Simplenetes_ Pod is an executable named `pod` which conforms to the _Simplenetes_ Pod _API_.  
> For more technical details, check out the _Pod API_ section in [https://github.com/simplenetes-io/podc/blob/master/PODSPEC.md](https://github.com/simplenetes-io/podc/blob/master/PODSPEC.md).

The Proxy Pod mentioned above does not run any containers. It runs directly on the Host as a native application, but it is managed simply as a Pod. However, you don't need to bother about that.

### The Pod compiler (podc)
The Pod compiler is a separate project which compiles _pod.yaml_ files into standalone `pod` executables that take advantage of `podman` as the container runtime.

### Other Pod types
For example, the _Simplenetes_ Proxy is treated as a regular Pod, but is is not containerized because it accesses _.conf_ files placed by the daemon in the host's root directory. The _Simplenetes_ Daemon however does not know the difference.  
As long as the Proxy is provided in the form of a `pod` executable and that it conforms to the Pod _API_, the Daemon can manage the Pod's lifecycle.

## Hosts
Represented by a [_Virtual Machine_](https://en.wikipedia.org/wiki/Virtual_machine), a bare metal machine, or your laptop. The Host is part of a Cluster.

A Host runs Pods.

Hosts are, in _Simplenetes_ terminology, divided into **load balancers** and **workers**. Load balancers are exposed to the public Internet, while workers are not. Workers receive traffic from the load balancers via the internal proxy.

A Host is expected to be configured with `podman`, if it is expected to run container Pods (`sns` will set this up for you).

If a Host is meant to receive public Internet traffic directly, then it is likely going to be running an Ingress Pod.

Any Pod is allowed to bind to the Host network or map ports to the Host interface (the one expected to be publicly exposed), as long as the firewall rules allow the specified traffic settings.

Hosts which are workers usually are not exposed directly to the Internet, but receive traffic from the internal proxy which is then transmitted to Pods running on the Host according to the Pod ingress rules.

When _Simplenetes_ is connecting to a Host it reads the _host.env_ file and uses that information to establish a secure connection with the Host (using [_SSH_](https://en.wikipedia.org/wiki/Secure_Shell_Protocol)).

A Host can declare in its _host.env_ file a `JUMPHOST`, informing the _SSH_ connection that a connection to that particular host must be established first before connecting to the actual Host. This is the recommended way of doing it, so that worker Hosts are not exposed to incoming traffic from the public Internet at all.

If the _host.env_ file has `HOST=local` set, then it does not connect via _SSH_, it "connects" directly to local disk. Using local disk as host target is great for local development. In that case, a host representation is created on disk using the `sns host register` command.

## Clusters and Cluster Projects
A Cluster is a one or many hosts on the same [_VLAN_](https://en.wikipedia.org/wiki/Virtual_LAN). A Cluster can be as simple as your laptop running `sns`.

Typically, a Cluster is one or two load balancer Hosts exposed to the Internet on ports `80` and `443`, together with a couple of worker hosts where Pods are running.

A Cluster is mirrored as a _Git_ repository on the operators local disk (or in a _CI/CD_ system). In the context of _Simplenetes_, that repo is referred to as a Cluster Project.

The Cluster being mirrored as the directory structure is a design choice. We believe this brings a low mental burden on grasping the system as a whole. It also gives understandable, traceable _GitOps_ procedures in a way that you can inspect the full cluster layout right from the _Git_ repo.

A Cluster Project is a _Git_ repository which mirrors the full Cluster with all its Hosts. Hosts are organized as subdirectories in the repo. Each Host is identified by having a _host.env_ file inside of it.

A Cluster is managed by the `sns` tool.

When syncing to a Cluster from a Cluster Project, _Simplenetes_ will connect to each Host (in parallel) and update the state of files on the Host by copying, modifying and deleting files as necessary, so it mirrors and matches the contents of the Cluster Project at the end of the process.

Following _GitOps_ procedures, the sync will not be allowed if the Cluster repo branch which we are syncing from is behind the Cluster itself, unless forced, such as in cases major rollbacks are deemed necessary.

The Daemon running on each Host will pick up the changes and manage the state changes of the Pods.

### Typical Cluster setup
A common example setup is composed of a [VPC](https://en.wikipedia.org/wiki/Virtual_private_cloud) with two load balancer Hosts (exposed to the Internet and open on ports `80` and `443`) combined with two worker hosts, which only accepts traffic coming from within the _VLAN_. Finally, a fifth host, which we call the "backdoor", is exposed to the Internet on port `22` for handling _SSH_ connections. All _SSH_ connections made to any load balancer or worker Host are always jumped via the backdoor Host. This reduces the surface area of attack since none of the known _IP_ addresses are open to _SSH_ connections coming from the Internet.

Setting up the Cluster with its _Virtual Machines_ is described in more detail in the [Provisioning a production cluster](PROVISIONING.md) section.

## Proxy and clusterPorts
For Pods to be able to communicate with each other within the Cluster and across Hosts, there is a concept of `clusterPorts` and the _Simplenetes_ Proxy.

A Pod which is open for traffic via the Proxy declares a `clusterPort` in its `expose` section in the _pod.yaml_ file. A `clusterPort` is then targeted at a specific port inside the Pod. Other Pods can open connections to that `clusterPort` from anywhere in the Cluster and be proxied to any Pod exposing that `clusterPort`.

> Note 1: there can be multiple replicas of a specific Pod version listening to the same `clusterPort`, which means traffic will be shared among them.  

> Note 2: when softly rolling out a new Pod version, the new version could also share the same `clusterPort` to guarantee no downtime occurs. That works because traffic is shared between old and new Pod versions until the old version(s) are removed.

> Note 3: when setting `clusterPorts` manually one can force totally different Pods to share the incoming traffic by having them use the same cluster ports setting. Normally cluster ports are automatically provided by `sns`.

> Note 4: Pods which receive traffic from the Ingress by matching domain names and _URLs_ can operate with automatically assigned cluster ports.

> Note 5: for Pods which are to serve internally, those are required to set fixed cluster ports so that other Pods know how to connect to them.

When a process inside a container wants to connect internally to another Pod, it does so by opening a [_TCP_](https://en.wikipedia.org/wiki/Transmission_Control_Protocol) socket to `proxy:clusterPort`. `proxy` is expected to be a static host name automatically put into each containers hosts file (_/etc/hosts_), which points to the hosts internal _IP_ address.

The native Proxy Pod listens to a set of `clusterPorts` and its job is to proxy connections to another Proxy on a Host in the Cluster, which then can forward it to a Pod running on the Host.

The Proxy is very robust and simple in its cleverness. It requires very little configurations to work. It needs an updated list of Host addresses in the Cluster, as well as a _proxy.conf_ file to be generated by the Daemon, telling it what `clusterPorts` are bound on the Host. The Proxy itself will then, when proxying a connection, try all hosts for answering connections and remember the results for a while. This gives a robust and easy to manage system which is free from `iptables` hacks or constantly needing to update global routing tables when Pods come and go in the cluster.

A Pod can also bind directly to a specific `hostPort` on the host which it is running on. This is particularly useful for the Ingress Pod.

> Note6: Each clusterPort on a Pod is automatically mapped to a `hostPort`. It is this `hostPort` the Proxy connects to.

> Note7: `clusterPorts` are a set of _TCP_ ports being listened by all proxies across all hosts. Connecting to a `clusterPort` (on a Proxy) results in a connection from the Proxy to another Proxy and then to a mapped `hostPort`, which in turn connects to the `targetPort` inside the Pod.

## Ports range
Cluster ports are often automatically assigned, but they can be manually assigned in the range between `1024 and 65535`. Ports `30000-32767` are reserved for Host ports and the Proxy itself (which claims port `32767`).  
Auto-assigned Cluster ports are set in the range of `61000-63999`.  
Auto-assigned Host ports are set in the range of `30000-31999` (the full range of dedicated Host ports is `30000-32766`).

## Daemon
The _Simplenetes_ Daemon manages the lifecycle of all the Pods on the Hosts, regardless of their runtime type (be it `podman` or native executables).

It reads _.state_ files alongside the `pod` file and executes the `pod` file with arguments relating to the desired state of the Pod.

The _Simplenetes_ Daemon is installed and runs on each Host in a Cluster as a [_systemd_](https://www.freedesktop.org/wiki/Software/systemd/) service.  

The _Simplenetes_ Daemon is preferably installed with root privileges so that it can create _ramdisks_ for the Pods which require that, but it drops privileges when it interacts with any Pod script or executable.

The Daemon can be run as a foreground process in user mode instead of as root which is generally useful when running in development mode, for a single user, straight on the laptop.

## The sns management tool
The [_simplenetes_](https://github.com/simplenetes-io/simplenetes) repo provides the `sns` tool used to create and manage clusters.
