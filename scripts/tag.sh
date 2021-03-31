#!/usr/bin/env sh

if ! podVersion="$(./scripts/version.sh get)"; then
    exit 1
fi

printf "Tagging latest commit as: %s\\n" "${podVersion}"

git tag "${podVersion}"
