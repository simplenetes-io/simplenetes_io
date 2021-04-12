# Provisioning a prod-cluster on a host provider of choice

Provisioning a cluster is as easy as:  

1.  Setup your Simplenetes production cluster project
2.  Create one or many virtual machines
3.  Let Simplenetes setup the machines
4.  Maintaining your hosts

## 1.  Setup your Simplenetes production cluster project
Before we create any actual virtual machines, we create the Cluster Project.

```sh
sns cluster create prod-cluster
cd prod-cluster
```

In the next step we will create the virtual machines and gather the data we need to create the hosts representations on disk.

## 2. Create our Virtual Machines
There are many ways to accomplish this, both in automated fashions but also manually. In both cases the important things to accomplish are:  

1.  Create a virtual machine (a $10 machine is most often enough)
    Create it with a CentOS 8 image. Other images can work also, important thing is that it is a GNU/Linux box using `systemd` as init system and that `podman` can be installed onto it.
    CentOS and Podman both coming from RedHat makes a reliable combo.
    The firewall supported is firewalld, which comes with CentOS. Please do use a distro with firewalld.
    Create the machine with internal networking/private IP enabled.
2.  Make sure all VMS which are to be loadbalancers are exposed to the public internet, having a public IP.
3.  Make sure worker machines are not exposed to the public internet, but only on the internal network, they do not need a public IP but it is fine if they have because using firewalld
    we shut out any public traffic.

After you have created the VMs then let `sns` provision the machines for you to work with Simplenetes.

We will here show how to manually create a small cluster consisting of one loadbalancer and one worker machine on Linode.

We will also create a  _backdoor_ machine. A backdoor machine is an entry point into the cluster for our management tool. We want this because we want to keep the worker machines unexposed to the public internet but at the same to we need to access them via SSH. Another name for a _Back door machine_ host would be a _Jump host_.

We could use a loadbalancer as jump host to save us one VM, however it can be more secure not to expose SSH on the loadbalancers (which have known IPs in the DNS).

Preferably the _Back door machine_ is not exposed to DNS names and therefore not necessarily known to any attacker.

If you already have existing virtual machines, you can skip the following step.

### Create virtual machines on Linode

This process could be automated using some provisioner tool, but we'll do it by hand in this example.

Steps:  

1.  Login to Linode
2.  Create the loadbalancer1 machine (a $10 machine is enough)
    -   Use CentOS8 as operating system
    -   make sure PrivateIP is checked
    -   Set a root password (root login will later be disabled by sns)
    -   Label/tag the machine as you wish
    -   Copy the public and private IP addresses from the dashboard, they are refered later as
        `PubIP-Loadbalancer` and `PrivIP-Loadbalancer`.
3.  Create another machine as backdoor, a tiny VM is enough for this.
    - Same procedure as when creating the loadbalancer, remember the IPs.
4.  Create the worker1 machine (a $10 machine is enough)
    - Same procedure as when creating the loadbalancer, remember the IPs.

Make sure you have the root password(s) available, you will need them soon.

Note that if you are using a host provider which does not provide root login but superuser login or root with key login, then that works too. Then you can supply that information when registering the hosts in the sns cluster.

## 3. Let Simplenetes setup the machines
Now that we have the actual machines created we can use Simplenetes to provision the machines for us.
Simplenetes can prepare the machines by running a few commands for each host.

First we will create the virtual machines representations in the cluster project.

If your cloud provider creates a superuser for you then set that superuser below when creating the host. Then save the SSH key as `id_rsa_super` in the host directory, alternatively if you have the keyfile elsewhere you can provide the path using the -S option.

### Backdoor host

If your cloud vendor provided you with an existing super user, add the options `--super-user-name=given` and `--super-user-keyfile=path`.
Is is fine to have the keyfile stored outside the cluster repo.  
Relative paths are relative to the host directory inside the cluster repo, for example `../../secret-keys/id_rsa` gives you the possibility to store keys in a sibling directory to the cluster repo directory.

Setting the key paths as a way to keep keys outside of the cluster repo can be desirable in many situations for increased security.  

You can do that both for super user keys `(--super-user-keyfile=)` and for regular user keys `(--key-file=)`.  
It is possible to replace the host keys at any time in case you want to have them outside of the cluster repo at a later stage.


```sh
sns host register backdoor --address=<PubIP-Backdoor>
```

If you were provided with an already existing superuser with a keyfile you will not set it up here again, otherwise do that now:  

Add the `--root-keyfile=path` if the root login uses a key instead of password.

If you want the keys outside the cluster or reuse existing keys add the options `--super-user-name=given` and `--super-user-keyfile=path` when creating the superuser.

```sh
sns host setup superuser backdoor
```

Now we disable root login, using the super user accounts.

```sh
sns host setup disableroot backdoor
```

Configure firewalld on the host, but skip setting up things which is irrelevant to the backdoor.  
```sh
sns host setup install backdoor --skip-podman --skip-systemd
```

We disable the host to not be part of any sync action:  
```sh
sns host state backdoor -s disabled
```


### Loadbalancer1

Lets register the loadbalancer1. You can add options in the same way as for the *backdoor1*.

We add `--jump-host` so that we can manage this host via the internal network.  
We add `--expose` so that we open ports in the firewall which the loadbalancer wants incoming traffic on.


```sh
sns host register loadbalancer1 \
    --address=<PrivIP-Loadbalancer1> \
    --jump-host="../backdoor" \
    --expose="80 443" \
    --router-address=<PrivIP-Loadbalancer1>:32767

# If you were provided an already existing superuser you can skip the following two steps, same as for backdoor1.
sns host setup superuser loadbalancer1
sns host setup disableroot loadbalancer1

sns host setup install loadbalancer1
sns host init loadbalancer1
```

### Worker1

Note, we do not publicly expose any ports on worker hosts.

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

Each host is created as a sub directory inside the cluster project. Each host has a new `id_rsa` key generated (unless configured differently) and a `host.env` vars file created. A `host-superuser.env` file is also created for super user access to the host.

Using the superuser account we have provisioned the host by installing podman, creating the regular user and performing configurations. The `EXPOSE` variable in the `host.env` file states which ports should be open to the public. This is then configured using `firewalld` (if it is installed):  

Using our regular user we also init'ed the host as part of the cluster by setting the `cluster-id.txt` file on the host. If you are using an existing host this step you will always want to run, otherwise sync will not work because it cannot recognize the host as being part of the cluster.
It will also install the image registry config.json file, if any.


## 4.  Maintaining your hosts
You can easily step into a shell all your hosts by following these steps:  

```sh
sns host shell <host> [--super-user]
```

## 5. Adding pods
We'll show here how to add some initial pods to get the cluster up and running. See the DEVCLUSTER instructions for details on this.

Attach pods:  

```sh
cd prod-cluster
sns host attach ingress@loadbalancer1 --link=https://github.com/simplenetes-io/ingress.git
sns host attach proxy@loadbalancer1 --link=https://github.com/simplenetes-io/proxy.git
sns host attach proxy@worker1 --link=https://github.com/simplenetes-io/proxy.git
sns host attach letsencrypt@worker1 --link=https://github.com/simplenetes-io/letsencrypt.git
sns host attach simplenetes_io@worker1 --link=https://github.com/simplenetes-io/simplenetes_io.git
```

Configure the cluster:  
```sh
cd prod-cluster

# Allow HTTP ingress traffic for the simplenetes_io pod.
echo "simplenetes_io_allowHttp=true" >>cluster-vars.env
```

Compile all pods:  
```sh
sns pod compile simplenetes_io
sns pod compile proxy
sns pod compile letsencrypt
sns pod compile ingress
```

Generate ingress:  
```sh
sns cluster geningress
sns pod updateconfig ingress
```

Sync the cluster:  
```sh
git add . && git commit -m "Initial"
sns cluster sync
```
