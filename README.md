# simplenetes.io website pod

nginx powered site.

## Workflow
1. Get the pod running locally  
```sh
./scripts/compile.sh
podc
./pod run
./pod ps
curl 127.0.0.1:8181
```

2.  Edit files  
Edit files inside `./src`.
Recompile:  
```sh
./scripts/compile.sh
curl 127.0.0.1:8181
```

3. Take down pod when done
```sh
./pod rm
```

## Releasing

Compile the latest source:  
```sh
./scripts/compile.sh
```

Then we need to bump/set the `podVersion` in `pod.yaml`. We use the `./scripts/version.sh` script to do this.

Bump the version in `pod.yaml`:  
```sh
./scripts/version.sh bump
```

Or, to set the version do:  
```sh
./scripts/version.sh set 1.2.3-beta4
```

Then we need to commit changes, so we can tag the latest commit.  
```sh
git commit -am "bump version" &&
./scripts/tag.sh &&
git push
```

Images are automatically built by _GitHub Actions_ whenever a new tag is pushed.
