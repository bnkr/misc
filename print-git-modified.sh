#!/bin/sh
# Print updates to commit.

CODE_DIR="/home/bunker/src"

for dir in `echo ${CODE_DIR}/*`; do
  gitdir=${dir}/.git
  if test -d $gitdir -a \( ! -L $dir \); then
    cd $dir
    files=`git status --untracked-files=no | grep '#\s*\(modified\|new\|deleted\):' | sed 's/#\s*\(.*\)/\1/'`
    if test -n "${files}"; then
      echo "\\033[0;31m * $dir\\033[0;0m"
      echo "${files}"
    fi
    cd ..
  fi
done

