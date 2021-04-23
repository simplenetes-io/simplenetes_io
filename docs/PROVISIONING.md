# Provisioning a production Cluster on a Host provider of choice

Provisioning a Cluster is rather easy. The following 4-step process covers the most important tasks:  

1. Preparing your _Simplenetes_ production Cluster project
2. Creating one or more _Virtual Machines_
3. Let _Simplenetes_ setup the machines
4. Maintaining your Hosts
5. Attaching Pods to form the Cluster

## Setup your Simplenetes production cluster project
Before we create any actual virtual machines, we create the Cluster Project:
```sh
sns cluster create prod-cluster
cd prod-cluster
```

In the next step we will create the virtual machines and gather the data we need to create the Hosts representations on disk.

## Create our Virtual Machines
There are many ways to accomplish this, including automated or manual ways. The important things to accomplish are:  

1. Create a virtual machine (a $10 machine is most often enough)
    Create it with a [_CentOS_](https://www.centos.org/) 8 image. Other images may also work. The important thing is that it is a _GNU/Linux_ box using [_systemd_](https://www.freedesktop.org/wiki/Software/systemd/) as init system and that [`podman`](https://podman.io/) can be installed onto it.
    _CentOS_ and _Podman_ both coming from [_RedHat_](https://www.redhat.com/) makes _CentOS_ a reliable combo.
    The firewall supported is [`firewalld`](https://firewalld.org/), which comes with _CentOS_. Please do use a distro which ships with or supports `firewalld`.
    Create the machine with internal networking enabled (private _IP_).
2. Make sure all _VMs_ which are to serve as load balancers are exposed to the public Internet. That is, all machines have public _IPs_ associated to them.
3. Make sure worker machines are not exposed to the public Internet. They should only serve to communicate within the internal network. Workers do not need a public _IP_, but it is fine if they happen to do because `firewalld` can be used to block public incoming traffic.

After you have created the VMs, then let `sns` provision the machines for you to be ready to work with _Simplenetes_.

We will now approach how to manually create a small Cluster consisting of one load balancer and one worker machine on [_Linode_](https://www.linode.com/).

We will also create a _backdoor_ machine. A backdoor machine is an entry point into the Cluster for our management tool. We want this because we want to keep the worker machines unexposed to the public Internet, while at the same allowing access to them via [_SSH_](https://en.wikipedia.org/wiki/Secure_Shell_Protocol). Another name for a _Backdoor Host_ would be _Jump Host_.

We could use a load balancer as jump Host to save us one _VM_, however it can be more secure not to expose _SSH_ on the load balancers at all. That is mostly because the load balancers all have publicly known IPs listed in the _DNS_ settings. Preferably, the _Backdoor machine_ is not exposed to _DNS_ names and therefore not necessarily known to any potential malicious actors or attackers.

If you already have existing virtual machines, you can skip the following step.

### Create virtual machines on Linode

This process could be automated using some provisioner tool, but we'll do it by hand in this example.

Steps:  
1.  Login to _Linode_;
2.  Create the `loadbalancer1` machine (a $10 machine is enough)
  -   Use _CentOS 8_ as operating system;
  -   make sure `PrivateIP` is checked;
  -   Set a `root` password (`root` login will later be disabled by `sns`);
  -   Label/tag the machine as you wish, for later reference and identification;
  -   Copy the public and private _IP_ addresses from the dashboard. These will be referred later as follows:
    - `PubIP-Loadbalancer`;
    - `PrivIP-Loadbalancer`.
3.  Create another machine as `backdoor. A tiny VM is enough for this.
    - Same procedure as when creating the `loadbalancer`, take note of the _IP_ addresses.
4.  Create the `worker1` machine (a $10 machine is enough)
    - Same procedure as when creating the `loadbalancer`, remember the _IPs_.

Make sure you have the root password(s) available, you will need the credentials on the proceeding steps.

> Note: if you are using a host provider which does not provide root login, but superuser login or a root account with key login instead, then that is also going to work too. The login information can be supplied when registering Hosts in the `sns` cluster.


## Let Simplenetes setup the machines
Now that we have the actual machines created, we can use _Simplenetes_ to provision the machines for us.
_Simplenetes_ can prepare the machines by running a few commands for each Host.

First we will create the virtual machines representations in the Cluster project.

If your cloud provider creates a "superuser" account for you, then set that account below when creating the Host. Save the provided _SSH_ key as `id_rsa_super` in the destination Host directory. Alternatively, if you have the key file elsewhere you can provide the path using the `-S` option.

### Backdoor host
If your cloud vendor provided you with an existing super user, add the options `--super-user-name=<mysuperuser>` and `--super-user-keyfile=<path_to_keyfile>`. It is fine to have the keyfile stored outside the cluster repo.

> Note: Relative paths are relative to the Host directory inside the Cluster repo. For example `../../secret-keys/id_rsa` gives you the possibility to store keys in a sibling directory in relation to the Cluster repo directory.

Both super user keys `(--super-user-keyfile=)` and for regular user keys `(--keyfile=)` can be set to relative paths.  
It is possible to replace the Host keys at any time in case you want to have them outside of the Cluster repo at a later stage.

> Note: Setting the key paths as a way to keep keys outside of the cluster repo can be desirable in many situations for increased security.  

Now, proceed with backdoor host registration:
```sh
sns host register backdoor --address=<PubIP-Backdoor>
```

> Note: If you were provided with an already existing super user with an existing keyfile you will not set it up here again. In this case, skip the following step.

In case an existing super user has not been provided, proceed with that now. Make sure the `--root-keyfile=path` parameters are present if the root login uses a key file instead of password.

In case you want the keys to stay outside the Cluster directory or if you want to reuse existing keys, add the options `--super-user-name=given` and `--super-user-keyfile=path` when creating the superuser, accordingly.

Set up the backdoor Host:
```sh
sns host setup superuser backdoor
```

Now we disable root login, using the super user accounts:
```sh
sns host setup disableroot backdoor
```

Configure `firewalld` on the Host, but skip setting up things which are irrelevant to the backdoor Host in particular:  
```sh
sns host setup install backdoor --skip-podman --skip-systemd
```

We disable the host to not be part of any state synchronization action:  
```sh
sns host state backdoor -s disabled
```


### Loadbalancer1
In this section, let's proceed into registering the _loadbalancer1_. You can add options in the same way as done during the creation of _backdoor1_.

Other options we include this time are:
- We add `--jump-host` so that we can manage this Host via internal network connections.
- We add `--expose` so that we open ports in the firewall which the load balancer wants incoming traffic on.

The command line for registering the new load balancer Host is then:
```sh
sns host register loadbalancer1 \
    --address=<PrivIP-Loadbalancer1> \
    --jump-host="../backdoor" \
    --expose="80 443" \
    --router-address=<PrivIP-Loadbalancer1>:32767
```

After that, set up the new Host, exactly the same as done for _backdoor1_ on the previous step. Skip the following set of commands if an existing superuser is already present.
```
sns host setup superuser loadbalancer1
sns host setup disableroot loadbalancer1

sns host setup install loadbalancer1
sns host init loadbalancer1
```

### Worker1

Similar process is then repeated for the worker Host.

> Note: we do not publicly expose any ports on worker hosts.

```sh
sns host register worker1 \
    --address=<PrivIP-Worker1> \
    --jump-host="../backdoor" \
    --router-address=<PrivIP-Worker1:32767>

# If you were provided an already existing superuser you can skip the following two steps, same as for backdoor1.
sns host setup superuser worker1
sns host setup disableroot worker1

sns host setup install worker1
sns host init worker1
```

### About hosts
Each Host is created as a subdirectory inside the Cluster project. Each Host has a new `id_rsa` key file automatically generated (unless configured differently) and a _host.env_ file created. The latter lists environment variables. A _host-superuser.env_ file is also created for super user access to the Host.

Using the super user account we have provisioned the host by installing `podman`, creating a regular user account and performing configurations. The `EXPOSE` variable in the _host.env_ file states which ports should be open to the public. This is then configured using `firewalld` (if it is installed, as recommended):  

Using our regular user we also initialized the Host as part of the Cluster by setting the _cluster-id.txt_ file on the Host. If you are using an existing Host this step you will always want to run, otherwise synchronization will not work because it won't be able to recognize the Host as being part of the Cluster.
Lastly, it will also install the image registry _config.json_ file, if present.


## Maintaining your hosts
Maintenance is easily accessible through direct shell access. Step into a shell in any of your hosts at any time with:  
```sh
sns host shell <host> [--super-user]
```

## Adding pods
After the base Cluster setup, this section covers the addition of some initial pods to get the Cluster finally up and running. For more information about Clusters, see also the [Setting up your first dev cluster](DEVCLUSTER.md) section.

Attach pods:  
```sh
cd prod-cluster
sns host attach ingress@loadbalancer1 --link=https://github.com/simplenetes-io/ingress.git
sns host attach proxy@loadbalancer1 --link=https://github.com/simplenetes-io/proxy.git
sns host attach proxy@worker1 --link=https://github.com/simplenetes-io/proxy.git
sns host attach letsencrypt@worker1 --link=https://github.com/simplenetes-io/letsencrypt.git
sns host attach simplenetes_io@worker1 --link=https://github.com/simplenetes-io/simplenetes_io.git
```

Configure the Cluster to allow _HTTP_ ingress traffic for the `simplenetes_io` Pod:  
```sh
cd prod-cluster
echo "simplenetes_io_allowHttp=true" >>cluster-vars.env
```

Compile all pods:  
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
