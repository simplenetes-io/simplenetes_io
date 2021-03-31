#!/usr/bin/env sh

test -z "$(git status --porcelain)" || {
    printf "Git repo not comitted, cannot tag.\\n" >&2
    exit 1;
}

if ! podVersion="$(./scripts/version.sh get)"; then
    exit 1
fi

printf "Tagging latest commit as: %s\\n" "${podVersion}"

git tag "${podVersion}"
