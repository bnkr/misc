#!/bin/sh
# Generate a random string from an alphabet string and a length.  It's much
# slower than the old php script (especially for large values of -l), but the 
# startup time is much less so you need not rely on the OS caching all php's 
# configs and so on.

print_help() {
  cat <<EOF 
usage: `basename ${0}` [-h] [-U] [-n] [-a] [-l LENGTH] [ALPHABET]...
Generate a random string.  With no arguments (except -l), it works as though
it was called with -a -n.  ALPHABET arguments are concatinated; spaces are 
ignored.

  -h      this message and exit.
  -l LEN  make a string of length LEN, default = 8.
  -U      use uppercase chars as well.
  -n      use numeric chars.
  -a      use lower-case alphabetic chars.
EOF
}

ALPHA=""
LEN=8
USE_UPPER=0
USE_LOWER=0
USE_NUMS=0

while test $# -gt 0; do
  case "$1" in
    -h)  print_help
         exit 0 ;;
    -U) USE_UPPER=1 
        ;;
    -a) USE_LOWER=1 
        ;;
    -l) if test "$#" -eq 1; then
          echo "Error: -l requires an argument." >> /dev/stderr
          exit 1
        fi

        shift
        if echo -n "$1" | grep [^0-9] > /dev/null; then
          echo "Error: argument to -l, '$1' is not numeric" >> /dev/stderr
          exit 1
        fi
        LEN=$1
        ;;
    -n) USE_NUMS=1 
        ;;
    -*) echo "Error: unrecognised argument '$1'" >> /dev/stderr 
        exit 1
        ;;
     *) ALPHA="${ALPHA}${1}"
  esac
  shift
done

if test x"$ALPHA" = x; then
  if test \( $USE_UPPER -eq 0 \) -a \( $USE_LOWER -eq 0 \) -a \( $USE_NUMS -eq 0 \); then
    USE_LOWER=1
    USE_NUMS=1
  fi

  if test $USE_LOWER -eq 1; then ALPHA="abcdefghijklmnopqrstuvwxyz"; fi
  if test $USE_UPPER -eq 1; then ALPHA="${ALPHA}ABCDEFGHIJKLMNOPQRSTUVWXYZ"; fi
  if test $USE_NUMS -eq 1; then ALPHA="${ALPHA}0123456789"; fi
fi

bytes=4
maxlen=`echo -n $ALPHA | wc -c`
while test ! $LEN -eq 0; do
  rand=`head -c ${bytes} /dev/urandom | od -t u4 -N ${bytes} | head -1 | awk '{print $2 }'`
  # From 1 to maxlen.
  rand=$((1 + $rand % $maxlen))
  c=`expr substr "$ALPHA" $rand 1`
  echo -n "$c"
  LEN=$((LEN-1))
done
echo
