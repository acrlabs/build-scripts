#!/usr/bin/env bash
set -euo pipefail

is_clean() {
    [[ -z "$(git status --porcelain --untracked-files=no)" ]]
}

release_tag() {
    git tag --points-at HEAD \
        | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' \
        | sort -V \
        | tail -n 1
}

tag=""
if is_clean; then
    tag=$(release_tag) || true
fi

if [[ -n "$tag" ]]; then
    printf "%s" "${tag}"
else
    git ls-files -s -- ${DOCKER_IMAGE_TAG_PATHSPECS[@]} | sha256sum | cut -c1-10
fi
