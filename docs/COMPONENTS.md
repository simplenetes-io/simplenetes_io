# The Components and Terminology of Simplenetes

This document gives an overview of everything involved in _Simplenetes_.

At an architechural view there is nothing more to know than what is in this document.

The goal for _Simplenetes_ is to be composed of as few moving parts as possible, while having a robust and easy to understand design. You will not find any `iptables` nor any `etcd` cluster.

The parts are:

- Pods
    Including:  
    - Ingress pod
    - Proxy pod
    - Letsencrypt pod
    - The pod compiler (`podc`)
- Hosts
- Clusters and Cluster Projects (as _Git_ repositories)
- The Proxy and clusterPorts
- Daemon (`simplenetesd`)
- The `sns` management tool

## Pods
A Simplenetes Pod is the same as a Kubernetes Pod in the sense that it is one or many containers which are managed together and share the same network.

A Simplenetes Pod is described in a simple `pod.yaml` file format and it is compiled into a standalone shell script which uses `podman` as container runtime.

The standalone `pod` shell script can be run as is, either locally or managed by the Simplenetes Daemon (`simplenetesd`) on a host.

The `pod` shell script uses `podman` to run containers, which is made for running containers as an unprivileged user (rootless). _Podman_ is compatible with _Docker_.

There are three special Pods in Simplenetes which most often are used in Clusters (but do not have to be):  
    - The Ingress pod: responsible for inbound traffic routing and TLS termination coming from the Internet (using _HAProxy_);  
    - The Proxy pod: an internal traffic router allowing Pods to talk to other Pods on other hosts or on the same host within the internal network;
    - The Letsencrypt pod: renews SSL/TLS certificates for all domains and makes them available to the Ingress pod.

Actually, Simplenetes pods do not have to be containers at all. A Simplenetes Pod is an executable named `pod` which conforms to the Simplenetes Pod API.

The Proxy pod mentioned above does not run any containers. It runs directly on the Host as a native application, but it is managed simply as a Pod. However, you don't need to bother about that.

### The Pod compiler (podc)
There is a separate project which compiles `pod.yaml` files into standalone `pod` executables which use `podman` as the container runtime.

### Other Pod types
For example, the Simplenetes Proxy is treated as a regular Pod, but is is not containerized because it accesses _.conf_ files placed by the daemon in the host's root directory. The Simplenetes Daemon however does not know the difference. As long as the proxy has a `pod` executable and conforms to the Pod API, the Daemon can manage it's lifecycle.

## Hosts
A Virtual Machine, a bare metal machine, or your laptop. It is part of a Cluster.

A Host runs Pods.

Hosts are in our terminology divided into _load balancers_ and _workers_. Load balancers are exposed to the public internet, while workers are not. Workers receive traffic from the loadbalancers via the internal proxy.

A Host is expected to be configured with `podman` if it is to run container pods (`sns` will set this up for you).

If a Host is meant to directly receive public internet traffic it would likely be running an Ingress pod.

Any pod could bind to the host network or map ports to the host interface to be publically exposed, as long as the firewall rules allow the specified traffic.

Hosts which are workers usually are not exposed directly to the internet, but receive traffic from the internal proxy which is then proxied to pods running on the host according to the pod ingress rules.

When Simplenetes is connecting to a Host it reads the `host.env` file and uses that information to establish an SSH connection to the Host.

A Host can declare in it's `host.env` file a `JUMPHOST`, which is used in the SSH connection to connect to first before connecting to the actual Host. This is a recommended way of doing it to not expose worker Hosts to incoming traffic from the public internet at all, so that all incoming connections made must be made via `jumphosts`.
p   

If the _host.env_ file has `HOST=local` set, then it does not connect via SSH, it "connects" directly to local disk, which is great for local development.

A host representation is created on disk using the `sns host register` command.

## Clusters and Cluster Projects
A Cluster is a one or many hosts on the same _VLAN_ (it can be as simple as your laptop).

A Cluster is typically one or two load balancer Hosts which are exposed to the internet on ports 80 and 443 and a couple of worker hosts where pods are running.

A Cluster is mirrored as a Git repo (Cluster Project) on the operators local disk (or in a CI/CD system).

This is a design choice that the cluster is mirrored as the directory structure. We believe this brings a low mental burden on grasping the system as a whole.

This also gives understandable, traceable GitOps procedures in a way that you can inspect the full cluster layout right from the Git repo.

A Cluster Project is a git repo which mirrors the full Cluster with all its Hosts. Each Host is a subdirectory in the repo and it is identified by having a _host.env_ file inside of it.

A Cluster is managed by the `sns` tool.

When syncing to a Cluster from a Cluster Project, Simplenetes will connect to each Host (in parallel) and copy/update/delete files on the Host, so it mirrors the contents of the Cluster Project.

Following GitOps procedures the sync will not be allowed if the cluster repo branch which we are syncing from is behind the cluster itself, unless forced for major rollbacks.

The Daemon running on each Host will pick up the changes and manage the state changes of the pods.

Setting up the Cluster with its Virtual Machines is described in the [Provisioning a production cluster](PROVISIONING.md) section.

Typically the setup is a VPC with two load balancer hosts (exposed to the internet and open on ports 80 and 443) combined with two worker hosts, which only accepts traffic coming from within the VLAN. Finally a fifth host, which we call the "backdoor", is exposed to the internet on port 22 (or some other port) for SSH connections. All SSH connections made to any load balancer or worker host is always jumped via the backdoor host. This reduces the surface area of attack since none of the known IP addresses are open to SSH connections coming from the Internet.

## Proxy and clusterPorts
For Pods to be able to communicate with each other within the Cluster and across Hosts, there is a concept of `clusterPorts` and the `Simplenetes Proxy`.

A Pod which is open for traffic via the proxy declares a `clusterPort` in its `expose` section in the `pod.yaml` file.

A `clusterPort` is then targeted at a specific port inside the Pod.

Other Pods can open connections to that `clusterPort` from anywhere in the Cluster and be proxied to any pod exposing that `clusterPort`.

Note1: that there can be multiple replicas of a specific pod version listening to the same `clusterPort`, which means traffic will be shared among them.  

Note2: when softly rolling out a new pod version, the new version could also share the same `clusterPort` to guarantee no downtime because traffic is shared between prior and new pod versions until the old versions are removed.

Note3: when setting clusterPorts manually one can force totally different pods to share the incoming traffic by having them use the same cluster ports. Normally cluster ports are automatically provided by `sns`.

Note4: for pods which receive traffic from the ingress by matching domain names and urls, they can operate with automatically assigned cluster ports. Pods which are to serve internally are required to set fixed cluster ports so that other pods know how to connect to them.

When a process inside a container wants to connect internally to another pod, it does so by opening a TCP socket to `proxy:clusterPort`. `proxy` is a static host name automatically put into each containers `/etc/hosts` file which points to the hosts internal IP address.

The native ProxyPod is listening to a set of clusterPorts and its job is to proxy connections to another Proxy on a host in the cluster which then can forward it to a pod running on the Host.

The Proxy is very robust and simple in its cleverness. It requires very little configurations to work. It needs an updated list of host addresses in the cluster, as well as a `proxy.conf` to be generated by the Daemon, telling it what clusterPorts are bound on the Host. The Proxy itself will then, when proxying a connection, try all hosts for answering connections and remember the results for a while. This gives a robust and easy to manage system which is free from `iptables` hacks or constantly needing to update global routing tables when pods come and go in the cluster.

A pod can also bind directly to a `hostPort` on the host which it is running on. This is useful for the Ingress pod.

Note5: Each clusterPort on a pod is (automatically) mapped to a `hostPort`. It is this `hostPort` the proxy connects to.

Note6: `clusterPorts` are a set of TCP ports being listened by all proxies across all hosts. Connecting to a `clusterPort` (on a proxy) results in a connection from the proxy to another proxy and then to a mapped `hostPort` which connects to the `targetPort` inside the pod.

Cluster ports are often automatically assigned, but they can be manually assigned in the range between `1024 and 65535`. Ports `30000-32767` are reserved for host ports and the proxy (which claims port `32767`).  
Auto-assigned cluster ports are set in the range of `61000-63999`.  
Auto-assigned host ports are set in the range of `30000-31999` (the full range of dedicated host ports is `30000-32766`).

## Daemon
The Simplenetes Daemon manages the lifecycle of all the Pods on the Hosts, regardless of their runtime type (be it `podman` or native executables).

It reads `.state` files alongside the `pod` file and executes the `pod` file with arguments relating to the desired state of the pod.

The Simplenetes Daemon is installed and runs on each Host in a Cluster as a systemd service.  

The Simplenetes Daemon is preferably installed with root privileges so that it can create `ramdisks` for the Pods which require that, but it drops privileges when it interacts with any pod script or executable.

The Daemon can be run as a foreground process in user mode instead of as root which is generally for running in "dev mode" for a single user straight on the laptop.

## The sns management tool
The is the _simplenetes_ repo which provides the `sns` tool used to create and manage clusters.
