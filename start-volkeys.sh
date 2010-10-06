#!/bin/sh
DATE=`date`
echo "* ${DATE} " >> ~/.volkeys-log
~/bin/volkeys -i 3 -d audigy >> ~/.volkeys-log 2>&1 &
