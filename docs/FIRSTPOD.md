# Creating your first Simplenetes pods

A Pod is described as a [_YAML_](https://en.wikipedia.org/wiki/YAML) file and it is compiled into a single executable, which is run together with [`podman`](https://podman.io/) (version `1.8.1` or later).

In this section we will create our first Pods and see how easy it is to manage their lifecycle using the standalone executable.

This is a crash course on how to work with Pods. For more examples, see also the [`podc` repository](https://github.com/simplenetes-io/podc/tree/master/examples).


## Installing
Before proceeding, make sure that `podc` and `podman` programs are available. Otherwise, see the [install section](INSTALLING.md) for instructions on installing the Pod compiler `podc`, as well as `podman`.


## Create a website pod
A very common scenario to apply _Simplenetes_ is when creating a website. Let's do that.

First, let's create the simplest possible Pod, before we move on to working with Pods in development mode.

### Quick Pod
Create a _mypod1_ directory. The directory name is important as it defines the default Pod name.
```sh
mkdir mypod1
cd mypod1
```

Copy the following _YAML_ contents and put them in a file called _pod.yaml_ inside the new _mypod1_ directory:
```yaml
api: 1.0.0-beta2
podVersion: 0.0.1
runtime: podman
containers:
    - name: webserver
      image: nginx:1.16.1-alpine
      expose:
          - targetPort: 80
            hostPort: 8181
```

Then compile and run the _pod_:  
```sh
podc
# podc command generated the pod shell script which we will be using to manage the pod

./pod run

# If you see:
# [ERROR] Host port 8181 is busy, can't create the pod mypod1-0.0.1
# Then change the containers/expose/hostPort setting to a different, open port. Then compile and run again.

./pod ps
curl 127.0.0.1:8181
./pod logs
./pod rm
```

The above is a simple and quick way to create a Pod. That could be all we need to do if we just want to use an existing image and run it.

However, we want to see how to develop an application living inside a Pod, that's what we are looking at next.

### Pods in development

In this section, we will see how to create a pod which we also want to work with in development mode. With that, we are going to be able develop and test our application locally.

When developing a website, for instance, one can use many different backend servers and technologies, be it [_NGINX_](https://www.nginx.com/), [_Hugo_](https://gohugo.io/), [_Express_](https://expressjs.com/), [_Jekyll_](https://jekyllrb.com/), [_Make_](https://www.gnu.org/software/make/), [_webpack_](https://webpack.js.org/), etc.

It is often the case that developers run their projects without using containers when in development mode, but when using **Simplenetes** it is very straight forward to always run in containers. In this way, development resembles production environment more closely and you can have all your microservices available.

_Simplenetes_ has a simple way of separating between processes such as _development_ and _production_ mode for when working with Pods by using a basic text _preprocessor_, as we will see in the _pod.yaml_ below.

Create a new Pod directory:  
```sh
mkdir mypod2
cd mypod2
```

This is our Pod _YAML_. Copy it and save it as _pod.yaml_ inside your newly created Pod directory.  

```yaml
api: 1.0.0-beta2
podVersion: 0.0.1
runtime: podman

#iftrue ${devmode}
volumes:
    - name: nginx_content
      type: host
      bind: ./build
#endif

containers:
    - name: webserver
      restart: always
      signal:
          - sig: HUP
#ifntrue ${devmode}
      image: webserver:0.0.1
#endif
#iftrue ${devmode}
      image: nginx:1.16.1-alpine
      mounts:
          - volume: nginx_content
            dest: /nginx_content
      command:
          - nginx
          - -c
          - /nginx_content/nginx.conf
          - -g
          - daemon off;
#endif
      expose:
          - targetPort: 80
            hostPort: 8181
```

Save the following as file named _pod.env_ alongside the _pod.yaml_ file:  
```sh
devmode=true
```

The blocks in the _YAML_ between the `#iftrue ${devmode} / #endif` directives will only be present when `devmode=true` is set in the _pod.env_ file. The reverse is, of course, true for cases when the _if not true_ (`#ifntrue`) directive is applied.  

Using these simple text preprocessor directives we can easily switch our Pod between development and production mode.  

When attaching a Pod to a Cluster project and compiling it targeting the Cluster, this local _pod.env_ file is ignored and values are instead read from the cluster-wide _cluster-vars.env_ file. There is no need in changing the `devmode` value from `true` to `false` in the _pod.env_ file when going from development to production mode in this case.

The Pod (when in devmode) will mount the _./build_ directory. This directory is expected to have _nginx_ content files. The generation of the content files are at the discretion of the website projects build process. We will manually create the files in this example.

The following snippets create two files inside the _./build/_ and _./build/public_ directories, respectively.

Save the following as _./build/nginx.conf_:  
```conf
user  nginx;
worker_processes  auto;

error_log  /dev/stderr warn;
pid        /var/run/nginx.pid;

events {
    worker_connections  1024;
}

http {
    types {
        text/html                   html htm shtml;
        text/css                    css;
        image/gif                   gif;
        image/jpeg                  jpeg jpg;
        application/javascript      js;
        image/png                   png;
    }

    default_type  text/html;

    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /dev/stdout  main;

    server {
        listen       80;
        server_name  _;

        location / {
            root   /nginx_content/public;
        }
    }
}
```

Save the following as _./build/public/index.html_ file:  
```
Hello world!
```

Now our Pod is setup and it can be compiled with:
```sh
podc
```

The `podc` command will generate an executable file simply named `pod`.

At this stage you can observe the resulting _YAML_ from the preprocessor stage by looking in the file _pod.yaml_.

Let's try and interact with the executable:  
```sh
./pod help
./pod info
./pod ps
```

Now, let's run the pod:  
```sh
./pod run
```

If you see an error message related to Host ports:
```
[ERROR] Host port 8181 is busy, can't create the pod mypod2-0.0.1
```
Then adjust the `containers/expose/hostPort` value inside the _pod.yaml_ file to an open port and recompile.


Send a request to it from the command line:
```sh
curl 127.0.0.1:8181
```

You should now see the reply:
```sh
Hello world!
```

Check the logs:  
```sh
./pod logs
```

Now you can update the contents of the _./build_ directory at your development process's discretion. In this case since using `nginx`, if you are updating the _nginx.conf_ file, the `nginx` process needs to be signalled so it can reload the workers. This is easy to do:  
```sh
./pod signal
```
This will signal `nginx` to reload the configuration.

The details on Pod signals and its configurations are specified in the [`podc` repository](https://github.com/simplenetes-io/podc/blob/master/PODSPEC.md).

Note that since the `nginx` process is running as the user `nginx`, it is important that the files inside _./build_ directory have public read access set. This is normally the case, but if you are running your development inside a _Virtual Machine_ with directories mounted to or from the host _OS_ (also known as shared folders), public permissions sometimes get stripped away.

When done, remove the Pod:  
```sh
./pod rm
```

### Pods in development and production
How would we go about moving this Pod from development to production release?

We will now see a complete pod setup which can work both with development and release processes.

Let's call this `mypod3`:  
```sh
mkdir mypod3
cd mypod3
```

Create the following files inside the directory: _pod.yaml_, _pod.env_ and _Dockerfile_.  
This process is similar to other more basic examples, but with some added preprocessing directives and cluster port configurations.

Contents for _pod.yaml_ file:  
```yaml
api: 1.0.0-beta2
podVersion: 0.0.1
runtime: podman

#iftrue ${devmode}
volumes:
    - name: nginx_content
      type: host
      bind: ./build
#endif

containers:
    - name: webserver
      restart: always
      signal:
          - sig: HUP
#ifntrue ${devmode}
      image: webserver:0.0.1
#endif
#iftrue ${devmode}
      image: nginx:1.16.1-alpine
      mounts:
          - volume: nginx_content
            dest: /nginx_content
      command:
          - nginx
          - -c
          - /nginx_content/nginx.conf
          - -g
          - daemon off;
#endif
      expose:
          - targetPort: 80
#iftrue ${devmode}
            # This property will be set when compiling in dev mode.
            # The variable will be read from the pod.env file.
            hostPort: ${HTTP_PORT}
#endif
#ifntrue ${devmode}
            # These properties are only set when NOT in dev mode.
            # HOSTPORTAUTO and CLUSTERPORTAUTO are port numbers which
            # will be automatically set when releasing in the cluster,
            # so we do not bother with defining them in out pod.env file.
            hostPort: ${HOSTPORTAUTO1}
            clusterPort: ${CLUSTERPORTAUTO1}
            sendProxy: true
            maxConn: 1024
#endif
```

Covering development, the _pod.env_ file is expected to contain:  
```env
devmode=true
```

The container is then described by the following _Docker_ configuration file (_Dockerfile_):
```Dockerfile
FROM nginx:1.16.1-alpine
COPY build /nginx_content
CMD ["nginx", "-c", "/nginx_content/nginx.conf", "-g", "daemon off;"]
```

With this setup you can have a Pod working for local development that can be released properly into a cluster.

Your build process should aim at building a _Docker_ image which is tagged and pushed properly, then the _pod.yaml_ `image` value needs to be set to that new image version accordingly.

For a living example of this, refer to the [Simplenetes website pod](https://github.com/simplenetes-io/simplenetes_io) on [_GitHub_](https://github.com/simplenetes-io).

The [next section](DEVCLUSTER.md) enters the subject of development Clusters in detail.
