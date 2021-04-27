# Setting up CI/CD for your cluster

The point of [Continuous Integration](https://en.wikipedia.org/wiki/Continuous_integration) and [Continuous Delivery](https://en.wikipedia.org/wiki/Continuous_delivery) (_CI/CD_) is to have an automated release flow. There are many ways of achieving this in _Simplenetes_. In the context of _Simplenetes_, what we always want to do in the end is to perform a cluster synchronization with `sns cluster sync`. The interesting questions come when analyzing how do we get to that point.

The release pipeline can potentially be run in three different places:  

-  from the Pod repository;
-  from the Cluster Project repo;
-  from the Management Project repo.

Most often the release pipeline is run from the Pod repo, because we want to swiftly release a new Pod version as soon as it is committed and pushed.

Releasing from Cluster Project repo pipelines and from Management Project repo pipelines are very similar to each other. The difference is merely if you have extracted the _SSH_ keys out from the Cluster Project into the Management Project or not.

## Release directly from within the Pod repo pipelines
The pros of this approach is that it is straight forward and we can get a fully automated release cycle this way.

The cons are that the Pod project will need access to Cluster keys to make the synchronization. In many cases, sharing the Cluster keys is not an issue because both the Dev and The Ops people are the same people.  
Another con is that we don't want to release many Pods simultaneously because it might cause a branch out of the Cluster repo and some releases might then get rejected.

### Example release from Pod repository
This is an example pipeline which is triggered whenever the Pod repo pipeline has performed a new build and tagged it for release:  
```sh
set -e

# Install sns, podc
# TODO

# We expect to be put inside the git repository directory of the pod.
podname="${PWD##*/}"
cd ..

# The cluster project is expected to exist and already have the pod "attached" and any configs imported already.
git clone "${clusterUrl}" .cluster  # Clone to a name we know will not clash with any pod name, hence the dot.
cd .cluster
export PODPATH="${PWD}/.."
export CLUSTERPATH="${PWD}"

# Let sns perform all release steps for a zero downtime version overlapping release.
# In the soft release patterns both the new and the previous versions of the pod are running simultanously as the ingress switches over the traffic to the new release and the removes the previous release(s).
# Perform a "soft" release and push all changes to the repo continously.
sns pod release "${podname}" -m soft -p
```

## Release from the Cluster/Management project repo pipelines
The pros of this approach are that we can separate access to the Pod repo from access to the _SSH_ keys, and also that we can release a number of Pods simultaneously.

The cons are that the pipelines need to be manually triggered in some way, expected to be run when a new Pod version has been pushed to the Pod repo.
Another drawback is that we need to pull the new Pod and possibly the Cluster project if this is a management project, so it involves a few more steps to get it going.

### Example release from Cluster or Management Project repository
The process for Cluster Project and Management Project are almost the same. We cover the Cluster project case below:  
```sh
set -e

# Install sns, podc
# TODO

# We expect to be put inside the git repository directory of the cluster project.
# The cluster project is expected already have the pod "attached" and any configs imported already.
# If doing this for a Management Project, we would at this point clone the cluster project.

export CLUSTERPATH="${PWD}"
export PODPATH="${PWD}/../pods"

cd ..
mkdir pods
cd pods
git clone "${podUrl}" "${podname}"
cd "${podname}"
git checkout "${podCommit}"
cd "${CLUSTERPATH}"

# Perform a "soft" release and push all changes to the repo continously.
sns pod release "${podname}" -m soft -p
```
