#!/bin/sh
# Repeatedly pings a host, by default bunkerprivate.com.

HOST=bunkerprivate.com
PINGS=25
SAMPLES=0

print_help() {
  echo "Usage: ping-test.sh [options]"
  echo "Repeatedly ping a host.."
  echo
  echo "  -h     this message."
  echo "  -i H   ip/host (default: bunkerprivate.com)."
  echo "  -s N   samples: how many times to run ping (default: 0 = infinite)."
  echo "  -p N   pings: how many packets per sample (default: 25)."
}

while test $# -gt 0; do
  case "$1" in
    -h) print_help
        exit 0 
        ;;
    -p) shift;
        if test $# -eq 0; then
          echo "-p requires an argument."
          exit 1;
        elif test $1 -lt 0; then
          echo "-p must be numeric and greater than 0."
        else
          PINGS=$1
        fi 
        ;;
    -s) shift;
        if test $# -eq 0; then
          echo "-s requires an argument."
          exit 1;
        elif test $1 -lt 0; then
          echo "-s must be numeric and greater than or equal to 0."
        else
          SAMPLES=$1
        fi 
        ;;
    -i) shift;
        if test $# -eq 0; then
          echo "-i requires an argument."
          exit 1;
        else
          HOST=$1
        fi
        ;;
     *) echo "Unrecognised argument: $1"; exit 1 ;;
  esac
  shift
done

while true; do
  ping -c $PINGS $HOST
  echo 
  echo ================
  echo 

  if test $SAMPLES -eq 1; then
    break
  else
    SAMPLES=$(($SAMPLES - 1))
  fi
done

