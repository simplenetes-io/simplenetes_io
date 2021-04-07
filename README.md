# simplenetes.io website pod

NGINX-powered site.

## Dependencies
- Python 3: https://www.python.org/downloads/
- pip: https://pip.pypa.io/en/stable/installing/
- mkdocs: https://www.mkdocs.org/#installing-mkdocs
```
pip3 install mkdocs
# Add the install to PATH, if necessary
# PATH=$PATH:/home/<user>/.local/bin
```
- mkdocs theme: https://github.com/squidfunk/mkdocs-material
```
pip3 install mkdocs-material
```

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

Note that in case an underlying virtual machine or some other factor such as shared mount is involved, it might be required to (re)set permissions:
```
./pod shell "chmod -R 755 /nginx_content"
```

3. Take down pod when done:
```sh
./pod rm
```

## Releasing

Bump/set the `podVersion` in `pod.yaml`. We use the `./scripts/version.sh` script to do this.

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
git push &&
git push --tags
```

Images are automatically built by _GitHub Actions_ whenever a new tag is pushed.
