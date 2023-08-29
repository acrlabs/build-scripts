set -ex

if [ "$(git status --porcelain --untracked-files=no)" ]; then
    GIT_INDEX_FILE=`mktemp`
    echo -n "-"
    cp .git/index $GIT_INDEX_FILE
    git add -u
    git write-tree
    git reset -q
    rm -f $GIT_INDEX_FILE
fi
