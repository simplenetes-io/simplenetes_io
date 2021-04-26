# Workflow for working with your development and releases

The following is an example of how you might go about getting started with **Simplenetes** and getting into a productive workflow.  

## Microservices
One of the tricky parts of working with microservices is how to run, develop and test them locally since they often depend on each other.

For example, when working with a single _Node.js_ process, during development, it is quite often the case to run it directly on the base _OS_ (bare metal) instead of running it inside a container. When one _Node.js_ process needs to communicate with another process, as microservices are designed to do, it can start getting tricky (at times, to the point of becoming messy) trying to run all processes outside of containers.

With _Simplenetes_ it is possible, with little efforts, to run local Clusters which mimic microservices architecture while staying in the same snappy local workflow on your own computer.

## Single service or Pod
If you are developing with focus on a single Pod, without the need or dependency on other microservices, then you could simply use the single Pod development workflow for developing the service (see the [_Creating your first Simplenetes pods_](FIRSTPOD.md) section). Then when willing to try it out in a local Cluster, it is possible to step into this type of process.

## Development mode
The important part when working with a development Cluster locally is to set the `<podname>_devmode` variable to `true` in `cluster-vars.env` e.g. `podname_devmode=true`. In the _pod.yaml_ file, this should make the Pod mount the _build_ directory for your project.   
So, when a pod is compiled and synced to the Cluster, which is just another directory on your laptop, that pod can still mount the build directory. Changes to the directory are reflected to the Cluster, in a way that it always remains up to date.

## Iterating
About up-to-date state and synchronization, the involved services may need to get signalled to properly reload updates. For example, when updating a _nginx.conf_ file the `nginx` process expects to get a hang up signal (`SIGHUP`) so that it knows the configuration needs to be reloaded.  
If the Pod has properly configured signals, then signalling the Pod is as easy as executing the following command:
```
sns pod signal podname
```
