#!/bin/sh
# 
# For a list of files, check that the file has an include guard, and if not then
# add one, which will look like:
#
#   #ifndef FILE_NAME_EXT_random
#   #define FILE_NAME_EXT_random
#   #pragma once
#
#   // rest of the file
#
#   #endif
#
# This script expects that random is [0-9a-z], and the header is [A-Z_].  This
# is only sufficiant to test something which works by my own conventions!
#
# TODO:
#   test for presence of filename, not guard regexpt: regexp is
#
#     #ifndef FILENAME...
#
#   So we have -r (for matching regexp), and -f.
#
# TODO:
#   -v for verbose (print what is going on)
#
# TODO:
#   -c for check -- see which ones don't have it.
#

VERBOSE=0
SIMULATE=0
FIND=0

MATCH_PRAGMA=1
MATCH_REGEXP=2
MATCH_FILE=3
MODE=0

print_help() {
  echo "usage: include-guards.sh: [options].. files..."
  echo "Add preprocessing guards to a file."
  echo
  echo "Options:" 
  echo "  -h, -help      this message and quit."
  echo "  -v, -verbose   print when headers have or have not got guards unless finding."
  echo "  -s, -simulate  don't modify files.  Irrelevant if -find."
  echo "  -f, -find      print files which do not have guards. -v is ignored with this."
  echo
  echo "Guard matching modes:"
  echo "  -r, -regexp  match regexp #ifndef [A-Z_]+[a-z0-9]+ (this is the default)."
  echo "  -n, -name    match the filename in uppercase, like #ifndef BLAH_BLAH_HPP."
  echo "  -p, -pragma  match #pragma once."
}

pwg=`which pwgen.sh`
if test "${pwg}" = ""; then
  echo "error: pwgen.sh must be in the path." 1&>2
  exit 1;
fi

errors=0
FILES=""
for arg in $*; do
  case "$arg" in
    -h |  -help)
    print_help
    exit 0;
    ;;

    -v | -verbose)
    VERBOSE=1
    ;;

    -v | -verbose)
    VERBOSE=1
    ;;

    -f | -find)
    FIND=1
    ;;

    -r | -regexp)
    MODE=$MODE_REGEXP
    ;;

    -p | -pragma)
    MODE=$MODE_PRAGMA
    ;;

    -n | -name)
    MODE=$MODE_FILE
    ;;

    *)
    if test \( ! -f "$arg" \) -o \( ! -r "$arg" \); then
      echo "error: input '$arg' does not exist, is not a regular arg, or is not readable" 1>&2
      errors=1
    fi

    FILES="${FILES} ${arg}"
  esac
done

if test $errors -eq 1; then
  echo "error: no operations have been performed." 1>&2
  exit 1;
fi

# default it (done here so we can check mutual exclusivity of it)
if test $MODE -eq 0; then
  MODE=$MATCH_REGEXP
fi

TEMP=$(tempfile) || exit 1
trap "rm -f -- ${TEMP}" EXIT 

for file in $FILES; do
  header=`echo $file | tr [a-z] [A-Z] | tr .- __`

  case $MODE in
    $MATCH_REGEXP)
    head -n 10 $file | grep '#ifndef [A-Z_]\+[a-z0-9]\+' > /dev/null
    no_match=$?
    ;;
    $MATCH_FILENAME)
    head -n 10 $file | grep "#ifndef ${header}" > /dev/null
    no_match=$?
    ;;
    $MATCH_PRAGMA)
    head -n 10 $file | grep "#pragma once" > /dev/null
    no_match=$?
    ;;
    *)
    echo "error: bad mode." 1>&2
    exit 1
    ;;
  esac

  if test $no_match -eq 1; then
    if test ${FIND} -eq 1; then
      echo $file;
    else 
      if test ${VERBOSE} -eq 1; then
        echo "${file} is unguarded"
      fi

      if test ${SIMULATE} -eq 0; then
        guard=${header}_`pwgen.sh`
        echo "#ifndef ${guard}" > ${TEMP}
        echo "#define ${guard}" >> ${TEMP}
        echo "#pragma once"     >> ${TEMP}
        echo >> ${TEMP}
        cat ${file} >> ${TEMP}
        echo >> ${TEMP}
        echo "#endif" >> ${TEMP}

        cp "${TEMP}" "${file}"
      fi
    fi
  else
    if test \( ${VERBOSE} -eq 1 \) -a \( ${FIND} -eq 0 \); then
      echo "${file} has guard"
    fi
  fi
done
