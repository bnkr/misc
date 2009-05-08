#!/bin/sh
#
# testnet.sh -d --dialog
#
#   -d --dialog   prints kdialog at the end.
#
COLBLUE="\033[1;34m"
COLGREEN="\033[1;32m"
COLRED="\033[1;31m"
COLRESET="\033[0m"
BROKEN=1

checkhost () {
  name=$1
  ip=$2

  echo -n "${COLBLUE}* $name${COLRESET}"
  ping -c 1 -q $ip > /dev/null 2>&1
  if test $? -ne "0"; then
    BROKEN=1
    echo " ${COLRED}down$COLRESET"
  else
    echo " ${COLGREEN}ok$COLRESET"
  fi
}

wait_retry() {
  echo "Retrying..."
  sleep 3;
}

DIALOG=0
if test "x$1" = "x--dialog" || test "x$1" = "x-d"; then
  DIALOG=1
fi

while test $BROKEN -eq 1; do
  BROKEN=0
  checkhost "Mulder:" 192.168.1.1
  if test $BROKEN -eq 1; then wait_retry; continue; fi
  checkhost "Scully:" 192.168.1.2
  if test $BROKEN -eq 1; then wait_retry; continue; fi
  checkhost "Csm:   " 192.168.1.3
  if test $BROKEN -eq 1; then wait_retry; continue; fi
  checkhost "Kuri:  " 192.168.1.4
  if test $BROKEN -eq 1; then wait_retry; continue; fi

  checkhost "Modem: " 192.168.100.1
  if test $BROKEN -eq 1; then wait_retry; continue; fi

  checkhost "Extern:" bunkerprivate.com
  if test $BROKEN -eq 1; then wait_retry; continue; fi
done

echo "All working!"

if test $DIALOG -eq 1; then
  kdialog --msgbox "The system is up again!"
fi

exit 0
