# Installing Simplenetes

There are three main components of _Simplenetes_ available to be installed:

1.  The Management Tool, called [`sns`](https://github.com/simplenetes-io/simplenetes)
2.  The Pod compiler, called [`podc`](https://github.com/simplenetes-io/podc)
3.  The Daemon, called [`simplenetesd`](https://github.com/simplenetes-io/simplenetesd)

To manage a Cluster, at least the `sns` tool needs to be installed on your computer.  
If managing the Cluster is expected to involve compiling Pods and creating new releases, then `podc` also needs to be installed.  
The Daemon (`simplenetesd`) should always be installed on all Cluster Hosts. It can also be installed locally on your laptop to simulate working on a Cluster.


## Prerequisites
To run Pods locally, `podman` version `1.8.1` or later is required. In order to take advantage of user-mode networking, `slirp4netns` is needed so that Pods can be run in rootless mode.  

### `podman`
Please refer to the [official documentation](https://podman.io/getting-started/installation) for instructions on how to install _Podman_.  
Alternatively, check your distribution's package manager. It's usually not more complicated than `sudo apt-get install podman`.

Since _Podman_ is expected to be used in unprivileged mode, we want to allow non-root users to bind ports from `80` and upwards.  
That can be achieved by adding the following row to _/etc/sysctl.conf_:  
```
net.ipv4.ip_unprivileged_port_start=80
```
Then, issue `sudo sysctl --system` to take the changes into effect.

### `slirp4netns`
For instructions about `slirp4netns`, please refer to the [official repository](https://github.com/rootless-containers/slirp4netns) on _GitHub_.


## Installing `sns`
`sns` is a standalone executable, written in [_POSIX_-compliant](https://en.wikipedia.org/wiki/POSIX) shell script and runs anywhere there is _Bash_/_Dash_/_Ash_ installed.
It interacts with a few programs in the _OS_, such as `grep`, `awk`, `date` and others. The usage of these tools is tailored to work under both _GNU/Linux_, _BusyBox/Linux_ and _BSD_ variants, including _OSX_. It might even run under [Windows Subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/) (_WSL_).

Download and install `sns` straight from [_GitHub_](https://github.com/simplenetes-io/simplenetes), as follows:  
```sh
LATEST_VERSION=$(curl -s -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/simplenetes-io/simplenetes/releases/latest | grep tag_name | cut -d":" -f2 | tr -d ",|\"| ")
curl -LO https://github.com/simplenetes-io/simplenetes/releases/download/$LATEST_VERSION/sns
chmod +x sns
sudo mv sns /usr/local/bin
```
For a complete list of versions, check out the [Releases](https://github.com/simplenetes-io/simplenetes/releases).


## Installing `podc`
Install `podc` and its runtime by downloading them from [_GitHub_](https://github.com/simplenetes-io/podc/releases), as follows:
```
LATEST_VERSION=$(curl -s -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/simplenetes-io/podc/releases/latest | grep tag_name | cut -d":" -f2 | tr -d ",|\"| ")
curl -LO https://github.com/simplenetes-io/podc/releases/download/$LATEST_VERSION/podc
curl -LO https://github.com/simplenetes-io/podc/releases/download/$LATEST_VERSION/podc-podman-runtime
chmod +x podc
sudo mv podc /usr/local/bin
sudo mv podc-podman-runtime /usr/local/bin
```

For more detailed instructions and explanation about the install process, please visit the [`podc` repository](https://github.com/simplenetes-io/podc/blob/master/README.md#install).


## Installing `simplenetesd`
`simplenetesd` is a standalone executable, written in _POSIX_-compliant shell script and will run anywhere there is _Bash_/_Dash_/_Ash_ installed.
The Daemon should always be installed onto the _GNU_/_BusyBox_/_Linux_ _Virtual Machines_ making up the Cluster.

It can also be installed onto your _GNU/BusyBox/Linux_ laptop or personal computer to simulate working on a Cluster.  
When installing it locally, `simplenetesd` does not have to be installed as a Daemon. It can be run in user-mode as a foreground process instead.

The Daemon activates the pod scripts that use `podman` to run containers.

To install `simplenetesd` locally to use it for development, do:
```sh
LATEST_VERSION=$(curl -s -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/simplenetes-io/simplenetesd/releases/latest | grep tag_name | cut -d":" -f2 | tr -d ",|\"| ")
curl -LO https://github.com/simplenetes-io/simplenetesd/releases/download/$LATEST_VERSION/simplenetesd
chmod +x simplenetesd
sudo mv simplenetesd /usr/local/bin
```

The provision of new Hosts and Clusters, as well as more details on `simplenetesd` are covered on the [_Provisioning a production cluster_](PROVISIONING.md) section.
