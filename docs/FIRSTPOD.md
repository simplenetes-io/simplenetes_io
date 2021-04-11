# Creating your first Simplenetes pods

A Pod is described in a _YAML_ file and is compiled into a single executable, which is run together with podman (version >=1.8.1).

In this HOWTO we will create our first pods and see how easy it is to manage their lifecycles using the standalone executable.

This is a crash course on how to work with pods, see [https://github.com/simplenetes-io/podc/tree/master/examples](https://github.com/simplenetes-io/podc/tree/master/examples) to learn all about pods.

## Installing
See [INSTALLING.md](INSTALLING.md) for instructions on installing the pod compiler `podc` and `podman`.

## Create a website pod
A very common scenario is to create a website. Let's do that.

First, let us just create the simplest pod possible, before we move on to working with pods in development mode.

### Quick Pod
Create a pod directory. The directory name is important as it defines the default name of the pod.
```sh
mkdir mypod1
cd mypod1
```

Cop the below _YAML_ and put it in a file called `pod.yaml` inside the new pod directory.

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

Then compile and run the pod:  
```sh
podc
# podc generated the pod shell script which we will be using to manage the pod

./pod run

# If you see:
# [ERROR] Host port 8181 is busy, can't create the pod mypod1-0.0.1
# Then change the expose/hostPort to a free port, compile and run again.

./pod ps
curl 127.0.0.1:8181
./pod logs
./pod rm
```

The above is a simple and quick way to create a pod. And could be all we need to do if we just want to use an existing image and run it.

However, we want to see how to develop an application living inside a pod, that's what we are looking at next.




### Pods in development

We will see how to create a pod which we also want to work with in development mode when developing our application locally.

When developing a website, one can use many different backend servers and build technologies, be it nginx, hugo, expressjs, jekyll, Make, webpack, etc.

It is often the case that developers run their projects without using containers when in development mode, but when using Simplenetes it is very straight forward to always run in containers. In this way development resembles production environment much better and you can have all your microservices available.

Simplenetes has a simple way of separating between processes such as _development_ and _production_ mode for when working with pods by using a basic text _preprocessor_, as we will see in the `pod.yaml` below.

Create a new pod dir:  
```sh
mkdir mypod2
cd mypod2
```

This is our pod YAML. Copy it and save it as `pod.yaml` inside your new pod dir.  

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

Save the following as file `pod.env` alongside the `pod.yaml` file:  
```sh
devmode=true
```

The blocks in the _YAML_ between the `#iftrue ${devmode} / #endif` directives will only be present when `devmode=true` in the `pod.env` file. The reverse is of course true for the _if not true_ `#ifntrue` directive.  

Using these simple text preprocessor directives we can easily switch our pod between dev and production mode.  

When attaching a pod to a cluster project and compiling it targeting the cluster, this local `pod.env` file is ignored and values are instead read from the cluster-wide `cluster-vars.env` file instead, so there is no need in changing the `devmode` value from `true` to `false` in the `pod.env` file when going from devmode to production mode in this case.

The pod (in devmode) will mount the `./build` directory. This directory is expected to have _nginx_ content files.  

The generation of the nginx content files are at the discretion of the website projects build process. We will manually create the files in this example.

Create these two files in `./build/` and `./build/public`, respectively:  

Save as file `./build/nginx.conf`:  

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

Save as file `./build/public/index.html`:  
```
Hello world!
```

Now our pod is setup and it can be compiled.  

```sh
podc
```

`podc` will generate an executable file simply named `pod`.

At this stage you can observe the resulting _YAML_ from after the preprocessor stage by looking in the file `.pod.yaml`.

Let's try and interact with the executable:  
```sh
./pod help
./pod info
./pod ps
```

Let's run the pod:  
```sh
./pod run
```

If you see the error message
```
[ERROR] Host port 8181 is busy, can't create the pod mypod2-0.0.1
```

Then adjust the `expose/hostPort` value in the `pod.yaml` to a free port and recompile.

```sh
# curl it
curl 127.0.0.1:8181
```

You should now see  
```sh
Hello world!
```

Check the logs:  
```sh
./pod logs
```

Now you can update the contents of the `./build` directory at your development process's discretion. In this case since using `nginx`, if you are updating the `nginx.conf` file the nginx process needs to be signalled so it can reload the workers. This is easy to do:  
```sh
./pod signal
```
This will signal nginx to reload the configuration.

How signals for pods are configured are specified in [https://github.com/simplenetes-io/podc/blob/master/PODSPEC.md](https://github.com/simplenetes-io/podc/blob/master/PODSPEC.md).

Note that since the `nginx` process is running as the user `nginx`, it is important that the files inside `./build` have public read access allowed. This is normally the case but if you are running your development inside a VM with mounted dirs to your OS, public permissions sometimes gets stripped away.

Remove the pod when done:  
```sh
./pod rm
```

#### Pods in development and production
How would we go about moving this Pod from production to release?

We will now see a complete pod setup which can work both with development and release processes.

Let's call this `mypod3`:  
```sh
mkdir mypod3
cd mypod3
```

Create the following files inside the directory. It is the same as above, but with some added preprocessing directives and cluster port configurations.

`pod.yaml`:  
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
            # so we do not bother with defining them in out `pod.env` file.
            hostPort: ${HOSTPORTAUTO1}
            clusterPort: ${CLUSTERPORTAUTO1}
            sendProxy: true
            maxConn: 1024
#endif
```

`pod.env:`  
```env
devmode=true
```

`Dockerfile`:
```Dockerfile
FROM nginx:1.16.1-alpine
COPY build /nginx_content
CMD ["nginx", "-c", "/nginx_content/nginx.conf", "-g", "daemon off;"]
```

With this setup you can have a pod working for local development but also which can be released properly into a cluster.

Your build process should aim at building a docker image which is tagged and pushed properly, then the `pod.yaml` `image` value needs to be set to that new image version.

For a living example of this look the [Simplenetes website pod](simplenetes-io).
