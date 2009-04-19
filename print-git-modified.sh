#!/bin/sh
# Print updates to commit.

CODE_DIR="/home/bunker/src"

COL_NONE="\\033[0;0m"
COL_RED="\\033[0;31m"

for dir in `echo ${CODE_DIR}/*`; do
  gitdir=${dir}/.git
  if test -d $gitdir -a \( ! -L $dir \); then
    cd $dir
    files=`git status --untracked-files=no | grep '#\s*\(modified\|new\|deleted\):' | sed 's/#\s*\(.*\)/\1/'`
    if test -n "${files}"; then
      echo "${COL_RED} * $dir${COL_NONE}"
      descr=`git describe 2> /dev/null`
      if test $? -eq 0; then
        echo "- ${descr}"
      fi
      echo "${files}"
    fi
    cd ..
  fi
done

