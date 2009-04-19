#!/bin/sh
# Print updates to commit.

CODE_DIR="/home/bunker/src"

COL_NONE="\\033[0;0m"
COL_RED="\\033[0;31m"
COL_BLUE="\\033[0;34m"
COL_GREEN="\\033[0;32m"

COL_RED_UL="\\033[4;31m"

COL_LBLUE="\\033[1;34m"
COL_LYELLOW="\\033[1;33m"
COL_LGREEN="\\033[1;32m"
COL_LRED="\\033[1;31m"
COL_LCYAN="\\033[1;36m"

for dir in `echo ${CODE_DIR}/*`; do
  gitdir=${dir}/.git
  if test -d $gitdir -a \( ! -L $dir \); then
    cd $dir
    files=`git status --untracked-files=no | grep '#\s*\(modified\|new\|deleted\):' | sed 's/#\s*\(.*\)/\1/'`
    if test -n "${files}"; then
      echo "${COL_LCYAN} * $dir${COL_NONE}"
      descr=`git describe 2> /dev/null`
      if test $? -eq 0; then
        echo "${COL_GREEN}- ${descr}${COL_NONE}"
      fi
      echo "${files}"
    fi
    cd ..
  fi
done

