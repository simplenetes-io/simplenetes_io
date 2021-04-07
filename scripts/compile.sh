#!/usr/bin/env sh
# This script is to compile the project.
# It's mission is to take what is in `./src` and get it to `./build`.
# In our case it's just to copy the dir, but in a more complex case this
# will invoke the build process of the application.

set -e

# If the build dir already exists we delete files inside of it but we do NOT delete the actual dir itself.
# It is important that we do not delete the build dir because if the pod is already running and has mounted the dir we need to keeps its inode intact.
if [ -d "./build" ]; then
    (cd build && rm -rf *)
else
    mkdir "build"
fi

cp -r src/* build/

# Write data to public directory
mkdocs build
cp -r ./site/* build/public
