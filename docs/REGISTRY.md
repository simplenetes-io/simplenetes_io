# Configuring image registries

[_Podman_](https://podman.io/) is compatible with the [_Docker_-style](https://www.docker.com/) [_config.json_](https://docs.docker.com/engine/reference/commandline/cli/#configjson-properties) file and _Docker_ registries.

Each Host will be configured with the _config.json_ file when running the `sns host init` command.

You can configure each Host separately by placing a file with the same format, but named as _registry-config.json_ inside the Host directory instead.

If no file is found in the Host directory then `sns` will look in the Cluster project base directory for the file and upload it for the Host.

The _registry-config.json_ file will be uploaded to the Host as `$HOME/.docker/config.json`. _Podman_ will pick this up when pulling images from private registries.

If changing the _registry-config.json_ for a Host (or all) you need to rerun `sns host init`.

## Generate the configuration file
If you already have a _config.json_ file you can copy it to _cluster-dir/registry-config.json_.

If you need to create a new registry config file, follow these steps:  
```sh
printf "docker.pkg.github.com:user:passwdOrtoken\\n" | sns cluster registry [host]
```

Or, do a `docker login` and then use file generated in _~/.docker/config.json_.
