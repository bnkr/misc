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

gc_directory() {
  dir=$1
  oldpwd=`pwd`
  cd $dir || fail "couldn't cd to repos containing dir"
  for f in *; do
    gc_repos $f

    if test ! -d "$repos/.git"; then
      continue
    fi

    for subdir in $f/*; do
      gc_repos $subdir

      # This catches $dir/build-aux/bcmake
      for subsubdir in $subdir/*; do
        gc_repos $subsubdir
      done
    done
  done
  cd $oldpwd
}

gc_directory "/home/bunker/src"
gc_directory "/home/bunker/writings"
