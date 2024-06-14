SHA=$(git rev-parse --short HEAD)
TAGS=$(git tag --points-at ${SHA})

if [ "$(git status --porcelain --untracked-files=no)" ]; then
    SUFFIX="-$(uuidgen -r)"
fi

for TAG in $TAGS; do
  if [[ $TAG =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo -n "${TAG}${SUFFIX}"
    exit 0
  fi
done

echo -n "${SHA}${SUFFIX}"
