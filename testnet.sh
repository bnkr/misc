#!/bin/sh
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

while test $BROKEN -eq 1; do
  BROKEN=0
  checkhost "Mulder:" 192.168.1.1
  checkhost "Scully:" 192.168.1.2
  checkhost "Csm:   " 192.168.1.3
  checkhost "Kuri:  " 192.168.1.4

  checkhost "Modem: " 192.168.100.1

  checkhost "Extern:" bunkerprivate.com

  if test $BROKEN -eq 1; then
    echo "Waiting to retry..."
    sleep 3;
  fi
done

echo "All working!"

exit 0
