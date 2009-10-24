#!/bin/sh
# Detects a missing copyright in the first 3 lines of the file and adds a
# message.

FORCE_COMMENT=
YEAR='2008-2009'
LICENSE="a 3-clause BSD license"
CHECK=0
VERBOSE=0
USE_STATUS=0
MESSAGE_FILE=

print_help() {
  echo "usage: addcopyright.sh [options]... files..."
  echo "Adds and checks for copyright messages in files."
  echo
  echo "Options:"
  echo "  -h, --help          This message and exit."
  echo "  -v, --verbose       Be verbose on stderr."
  echo "  -c, --check         Output a list of files with no copyrights."
  echo "  -s, --status        Status is non-zero if a file is found with no copyright.  Implies --check."
  echo "  -m, --message=FILE  File containing copyright message.  %%COMMENT%% is replaced with the comment chars."
  echo "  -l, --license=TEXT  Name of license.  Used to make a default copyright message if none given."
  echo "  -y, --year=TEXT     Year of copyright.  Used if no -m."
  echo "  -C, --comment=TEXT  Comment character.  Otherwise it's worked out automatically."
}

set_value_option() { 
  if test x$3 = 'x'; then
    echo "addcopyright.sh: missing value for $1." 1>&2
  fi
  eval "$2=$3"
}

# Works out the comment character based on the extension (defaults to '#')
find_comment() {
  case "$1" in
    *.cpp | *.hpp | *.c | *.h | *.hxx | *.cxx | *.php)
      COMMENT="//"
      ;;
    *.rb | *.cmake | */CMakeLists.txt | *.sh)
      COMMENT="#"
      ;;
    *)
      echo "warning: guessing comment caracter is '#'" 1>&2
      COMMENT="#"
      ;;
  esac
}

FILES=

while test $# -gt 0; do
  case "$1" in
    --help | -h)
      print_help 
      exit 0
      ;;
    --check | -c)
      CHECK=1
      ;;
    --verbose | -v)
      VERBOSE=1
      ;;
    --comment | -C)
      set_value_option $1 FORCE_COMMENT $2
      shift
      ;;
    --year | -y)
      set_value_option $1 YEAR $2
      shift
      ;;
    --license | -l)
      set_value_option $1 LICENSE $2
      shift
      ;;
    --message | -m)
      set_value_option $1 MESSAGE_FILE $2
      if test ! -r ${MESSAGE_FILE}; then
        echo "addcopyright.sh: message file '${MESSAGE_FILE}' is not readable." 1>&2
        exit 1;
      fi
      shift
      ;;
    --status | -s)
      USE_STATUS=1
      ;;
    -*)
      echo "addcopyright.sh: unrecognised argument: $1 (did you mean './$1'?)" 1>&2
      exit 1
      ;;
    *)
      FILES="${FILES} $1"
      ;;
  esac
  shift
done

if test "x$FILES" = "x"; then
  echo "addcopyright.sh: no files given." 1>&2
  exit 1
fi

copymsg=$(tempfile) || exit 1
temp=$(tempfile) || exit 1
trap "rm -f -- ${copymsg} ${temp}" EXIT 

if test "x$MESSAGE_FILE" = "x"; then
  cat <<EOF > $copymsg
%%COMMENT%% Copyright (C) ${YEAR}, James Webber.
%%COMMENT%% Distributed under ${LICENSE}.  See COPYING.

EOF
else
  cat $MESSAGE_FILE > $copymsg
fi

retval=0
COMMENT='#'
for f in $FILES; do
  head -3 $f | grep -q 'Copyright'

  if test $? -eq 1; then
    if test $CHECK -eq 0; then
      if test $VERBOSE -eq 1; then
        echo "$f: adding copyright" 1>&2
      fi

      if test x$FORCE_COMMENT = x; then
        find_comment $f
      else
        COMMENT=$FORCE_COMMENT
      fi

      sed "s|%%COMMENT%%|${COMMENT}|g" $copymsg | cat - $f > $temp
      cp $temp $f
    else
      # Check comments anyway for the error checking.
      find_comment $f
      echo $f
      if test $USE_STATUS -eq 1; then
        retval=1
      fi
    fi
  else
    if test $VERBOSE -eq 1; then
      echo "$f: has copyright." 1>&2
    fi
  fi
done

rm -f ${temp}

exit $retval
