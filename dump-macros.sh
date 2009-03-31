#!/bin/sh

for a in $*; do
  if test "x${a}" = "x-h"; then
    echo "Usage: dump-macros [file] [compiler=g++]"
    exit 0;
  fi
done

if test $# -ge 1; then
  file=$1
fi

compiler="g++"
if test $# -ge 2; then
  compiler=$2
  echo $*
fi

if test "x${file}" = "x"; then
  cmd="echo -n | ${compiler} -E -dM -"
  echo $cmd
  echo -n | ${compiler} -E -dM -
else
  cmd="${compiler} -E -dM ${file}"
  echo $cmd
  ${compiler} -E -dM ${file}
fi

exit $?
