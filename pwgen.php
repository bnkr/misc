#!/usr/bin/php
<?php
$OPTS = getopt("a:l:h");

function print_usage() {
  echo "usage: pwgen [-l LENGTH] [-a ALPHABET]\n";
  echo "Default alphabet is a-z0-9.  Default length is 8.\n";
}

#TODO: parse alphabet to have regexp charactr classes.

if (isset($OPTS['h'])) {
  print_usage();
  exit(0);
}

$alph = (isset($OPTS['a'])) ? $OPTS['a'] : "abcdefghijklmnopqrstuvwxyz0123456789";
$len  = (isset($OPTS['l'])) ? $OPTS['l'] : 8;

$alphmax = strlen($alph) - 1;
$pw = "";
for ($i = 0; $i < $len; ++$i) {
  $r = rand(0, $alphmax);
  $pw .= $alph[$r];
}
echo $pw . "\n";
?>
