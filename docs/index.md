# Simplenetes: magic-free clusters

Welcome to **Simplenetes**! Let's put the _Dev_ and _Ops_ back into [_DevOps_](https://en.wikipedia.org/wiki/DevOps).

## Introducing: Simplenetes clusters
_Simplenetes_ clusters enable setting up and managing a set of node machines for running applications within containers using [OS-level virtualization](https://en.wikipedia.org/wiki/OS-level_virtualization).  
The [`sns`](https://github.com/simplenetes-io/simplenetes/) tool is used to manage the full life cycle of your _Simplenetes_ clusters. 

> _Simplenetes_ integrates with [`podc`](https://github.com/simplenetes-io/podc/), the Pod compiler project used to turn Pods into executable units.

**Simplenetes** compared to [_Kubernetes_](https://kubernetes.io/):

- _Simplenetes_ has 100x less code than _Kubernetes_.
- _Simplenetes_ has fewer moving parts:
    - No external dependency to distributed data storage solutions such as _etcd_;
    - No complicated network policies and filtering programs such as _iptables_;
    - No requirement for administrative rights, super users or `sudo` to run. Containers are created, executed and managed in rootless mode;
    - Clusters are also [_Git_](https://git-scm.com/) repositories. See cluster data right on disk or from source control management systems;
    - Everything is managed via [_SSH_](https://en.wikipedia.org/wiki/Secure_Shell_Protocol);
    - No magic involved;
    - Very _GitOps_.
- _Simplenetes_ also supports:
    - Multiple replicas of Pods;
    - Overlapping versions of Pods;
    - Controlled rollout of Pods, allowing continuous deployment and releases;
	- Controlled rollback of Pods, complementing disaster recovery plans and state restoration;
    - Load balancing;
    - Internal proxying of traffic;
    - Continuous Integration and Continuous Delivery (_CI/CD_) pipelines;
    - [Let's Encrypt](https://letsencrypt.org/) certificates;
    - Health checks.
- _Simplenetes_ makes it really smooth to work with Pods and microservices in development mode on your laptop (_spoiler: no Virtual Machines required!_);
- _Simplenetes_ uses [`podman`](https://podman.io/) as container runtime.


In short, **Simplenetes** takes the raisins out of the cake, but it does not have everything _Kubernetes_ offers.

While _Kubernetes_ is "true cloud computing", in the sense that it can expand clusters with more worker machines as needed and it can request resources from the environment as needed (such as persistent disk), **Simplenetes** doesn't go there because that is when _DevOps_ becomes _MagicOps_.

## When should I use Simplenetes?

In what cases should I really consider using **Simplenetes**?

1.  You enjoy the simple things in life;
2.  You might have struggled getting into a good local development flow using _Kubernetes_;
3.  You know you will have a small cluster, between 1 and 20 nodes;
4.  You are happy just running _N_ replicas of a Pod instead of setting up auto scaling parameters;
5.  You want a deterministic cluster which you can troubleshoot in detail;
6.  You want less moving parts in your cluster.

In which cases should I **not** use **Simplenetes** over _Kubernetes_?

1.  _Simplenetes_ is in beta;
2.  Because you are anticipating having more than 20 nodes in your cluster;
3.  You need auto scaling in your cluster;
4.  You really need things such as namespaces;
5.  You are not using _Linux_ as your development machine;
6.  Your boss has pointy hair.



## Simplenetes explained

**Simplenetes** is composed of three parts:

- The [_simplenetes_](https://github.com/simplenetes-io/simplenetes/) repository, which is the `sns` tool to setup and manage clusters;
- The [_podc_](https://github.com/simplenetes-io/podc/) repo, which is the Pod compiler (`podc`) taking a Pod _YAML_ specification and transforming it into a standalone executable shell script used to manage Pods;
- The [_simplenetesd_](https://github.com/simplenetes-io/simplenetesd/) repo, which is the daemon (`simplenetesd`) running on each host to start and stop Pods, according to given state.

Look up in the documentation sections for topics and how to get started working with _Simplenetes_ clusters.

The [next section](./COMPONENTS/) covers more on the base theory, components of _Simplenetes_ and the terminology used.

**Simplenetes** was built by [@bashlund](https://twitter.com/bashlund) and [@filippsen](https://twitter.com/mikediniz).
