#!/bin/sh

comment='//'
year='2008-2009'

copymsg=$(tempfile) || exit 1
temp=$(tempfile) || exit 1
trap "rm -f -- ${copymsg} ${temp}" EXIT 

cat <<EOF > $copymsg
${comment} Copyright (C) ${year}, James Webber.
${comment} Distributed under a 3-clause BSD license.  See COPYING.

EOF


for f in $*; do
  echo "** $f"
  head -3 $f | grep -q 'Copyright'

  if test $? -eq 1; then
    cat $copymsg $f > $temp
    cp -v $temp $f
  else
    echo "already there."
  fi
done

rm -f ${temp}
