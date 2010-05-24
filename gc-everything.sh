#!/bin/sh

fail() {
  echo $1 1>&2
  exit 1
}

gc_repos() {
  repos=$1
  if test -d "$repos" && test -d "$repos/.git"; then
    cd $repos || fail "couldn't enter repository dir: $repos"
    echo "git gc on $repos"
    git gc --aggressive
    cd -
  fi
}

cd "/home/bunker/src" || fail "couldn't cd to source dir"

for f in *; do
  gc_repos $f

  if test ! -d "$repos/.git"; then
    continue
  fi

  for subdir in $f/*; do
    gc_repos $subdir
  done
done
