#!/bin/sh
# Make an simple apt repository using apt-ftparchive and dpkg-scansources, and
# also dpkg-scanpackages.
#
# Repos layout must be 
#
#   ./binary
#   ./source
#

for arg in $*; do
  if test "x$arg" = "-h"; then
    echo "usage: $0 [repos-root]."
    exit 0
  fi
done

if test $# -gt 1; then
  echo "error: only one argument, please." 1>&2
  exit 1
elif test $# -eq 1; then
  REPOS=$1  
else
  REPOS=`pwd`
fi

BIN="${REPOS}/binary"
SRC="${REPOS}/source"

if test ! -d "${BIN}"; then
  echo "error: ${BIN} is not a directory - give the repos root if it's not pwd"  >&2
  exit 1 
elif test ! -d "${SRC}"; then
  echo "error: ${SRC} is not a directory - give the repos root if it's not pwd"  >&2
fi

# TODO: here upload *.deb -> bindir and *.changes, build etc to srcdir.

dpkg-scansources source /dev/null | gzip -9c > ${SRC}/Sources.gz
test $? -eq 0 || exit $?
dpkg-scanpackages binary /dev/null | gzip -9c > ${BIN}/Packages.gz
test $? -eq 0 || exit $?

# TODO: sign the release files?!
