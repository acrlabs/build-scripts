set -ex

if [ "$(git status --porcelain --untracked-files=no)" ]; then
    echo -n "-" # separator character
    uuidgen -r
fi
