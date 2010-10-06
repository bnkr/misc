#!/bin/sh
#
# Adds a deb file to a local repository.

LOCAL_REPOS="/home/bunker/share-nobackup/apt-repos/binary"
LINTIAN=0
FILES=

print_help() {
  echo "Usage: local-add-deb.sh [option...] deb-binary-package"
  echo "Adds a .deb file to the local repository."
  echo
  echo "Options:"
  echo "  -h, --help      This message and exit."
  echo "  -l, --lintian   Run a lintian check on the .deb first."
}

exit_fail() {
  echo "$1" 1>&2;
  exit 1;
}

while test $# -gt 0; do
  case "$1" in
    -h | --help    ) print_help; exit 0; ;;
    -l | --lintian ) LINTIAN=1; ;;
    *)
      if test ! -f "$1"; then
        exit_fail "not a file: '${1}'"
      fi
      FILES="${FILES} $1"
      ;;
  esac
  shift
done

if test ! -d "${LOCAL_REPOS}"; then
  exit_fail "local repository '${LOCAL_REPOS}' is not a directory"
fi

if test "$LINTIAN" -eq 1; then
  for f in $FILES; do
    lintian "$f" || exit_fail "lintian failed"
  done
fi

for f in $FILES; do
  name=`basename "$f"`
  if test -e "${LOCAL_REPOS}/${name}"; then
    exit_fail "'$name' already exists in the repository"
  fi
done

for f in $FILES; do
  cp "$f" "${LOCAL_REPOS}" || exit 1
done

exec "/home/bunker/src/scripting/debian/buildrepos.sh"
