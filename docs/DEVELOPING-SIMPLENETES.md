# Developing Simplenetes

## Requirements
[_Space_](https://space.sh/) version `1.5.0` or later is required.

## Running the Simplenetes Space Module
When developing the module, we can run it without having to create a new release for each change.

To do so, set the `CLUSTERPATH` variable and optionally the `PODPATH` variable when running this _Space_ module.  
The `PODPATH` variable defaults to `${CLUSTERPATH}/_pods`.

Example:
```sh
export CLUSTERPATH=...
space /
```

## Create a new release of the sns executable
> Note: _Simplenetes_ is built using [_Space.sh_](https://space.sh) and it requires _Space_ to be installed in order to build the final standalone executable.

With _Space_ ready and available, run:  
```sh
./make.sh
```

The new release is saved to _./release/sns_.
