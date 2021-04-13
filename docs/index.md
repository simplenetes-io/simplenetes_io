# Simplenetes: magic-free clusters

Welcome to _Simplenetes_! Let's put the Dev and Ops back into DevOps.

>The sns tool is used to manage the full life cycle of your Simplenetes clusters. It integrates with the Simplenetes Podcompiler project podc to compile pods.

Simplenetes compared to Kubernetes:

- Simplenetes has a 100x less code than Kubernetes.
- Simplenetes has fewer moving parts
    - No etcd
    - No iptables
    - Root-less containers
    - Your cluster is also your git repo so you can see it on disk
    - Everything is managed via SSH
    - No magic involved
    - Very GitOps
- Simplenetes also supports:
    - Multiple replicas of pods
    - Overlapping versions of pods
    - Controlled rollout and rollback of pods
    - Loadbalancers
    - Internal proxying of traffic
    - CI/CD pipelines
    - Letsencrypt certificates
    - Health checks
- Simplenetes makes it really smooth to work with pods and micro services in development mode on you laptop (spoiler: no VMs needed)
- Simplenetes uses `podman` as container runtime


In short: Simplenetes takes the raisins out of the cake, but it does not have everything Kubernetes offers.

While Kubernetes is "true cloud computing" in the sense that it can expand your cluster with more worker machines as needed and it can request resources from the environment as needed such as persistent disk, Simplenetes doesn't go there because that is when DevOps becomes MagicOps.

## When should I use Simplenetes?

In what cases should I really consider using Simplenetes?

1.  You enjoy the simple things in life.
2.  You might have struggled getting into a good local development flow using k8s.
3.  You know you will have a small cluster, between 1 and 20 nodes.
4.  You are happy just running N replicas of a pod instead of setting up auto scaling parameters.
5.  You want a deterministic cluster which you can troubleshoot in detail
6.  You want less moving parts in your cluster

In which cases should I *not* use Simplenetes over Kubernetes?

1.  Simplenetes is in beta.
2.  Because you are anticipating having more than 20 nodes in your cluster.
3.  You need auto scaling in your cluster.
4.  You really need things such as namespaces.
5.  You are not using Linux as your development machine.
6.  Your boss has pointy-hair.



## Simplenetes explained

Simplenetes has three parts:

- The _simplenetes_ repo, which is the `sns` tool to setup and manages the cluster;
- The _podc_ repo, which is the pod compiler (`podc`) taking a pod yaml spec into an executable standalone shell script sied to manage the pod;
- The _simplenetesd_ repo, which is the daemon (`simplenetesd`) running on each host to start and stop pods, according to given state.

Look up in the documentation sections for topics and HOWTO get started working with Simplenets Clusters.

See the Components section for an overview of all components of Simplenetes and the terminology used.

Simplenetes was built by [@bashlund](https://twitter.com/bashlund) and [@filippsen](https://twitter.com/mikediniz).
