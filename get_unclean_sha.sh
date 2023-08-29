if [ "$(git status --porcelain --untracked-files=no)" ]; then
    echo -n "-"
	export GIT_INDEX_FILE=`mktemp` && cp .git/index $GIT_INDEX_FILE && git add -u && git write-tree && git reset -q && rm $GIT_INDEX_FILE
fi
