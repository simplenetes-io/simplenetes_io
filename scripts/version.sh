#!/usr/bin/env sh
# Get/Set/Bump version of pod.yaml

action="${1:-}"

if [ -z "${action}" ]; then
    printf "%s\n" "Usage: $0 [get | set <version> | bump]"
    exit 1
fi

shift
version="${1:-}"

set -e

STRING_IS_ALL()
{
    SPACE_SIGNATURE="str:0 pattern"

    local __str="${1}"
    shift

    local __pattern="${1}"
    shift

    local __m="[!${__pattern}]"
    case "${__str}" in
        (*${__m}*)
            return 1
            ;;
        *)
            ;;
    esac
}

_GET_VERSION()
{
    grep -m1 "^podVersion:" pod.yaml | awk -F: '{print $2}' | tr -d " \"'"
}

_BUMP_VERSION()
{
    local version="$(_GET_VERSION)"
    local major="${version%%[.]*}"
    local minor="${version%[.]*}"
    minor="${minor#*[.]}"
    local patch="${version##*[.]}"

    if ! STRING_IS_ALL "${patch}" "0-9"; then
        printf "Cannot bump patch number \"%s\" (of %s). Please set then new version as argument to $0 set <version>\\n" "${patch}" "${version}"
        return 1
    fi

    patch="$((patch + 1))"

    version="${major}.${minor}.${patch}"

    _SET_VERSION "${version}"
}

_SET_VERSION()
{
    if [ -z "${version}" ]; then
        printf "[ERROR] Version has to be provided\\n" >&2
        exit 1
    fi
    printf "Setting version to: %s\\n" "${version}" >&2

    local contents="$(cat pod.yaml)"
    if printf "%s\\n" "${contents}" | sed "s/podVersion:.*/podVersion: ${version}/" >pod.yaml.tmp; then
        mv pod.yaml.tmp pod.yaml
    fi
}

if [ "${action}" = "get" ]; then
    _GET_VERSION
elif [ "${action}" = "set" ]; then
    _SET_VERSION "${version}"
elif [ "${action}" = "bump" ]; then
    _BUMP_VERSION
else
    printf "[ERROR] Unknown action" >&2
    exit
fi
