#!/usr/bin/php
<?php
require_once("blib/debug.php");
require_once("blib/files/dirtools.php");

error_reporting(E_ALL&E_NOTICE);

function errln($str) {
  fwrite(STDERR, $str . "\n");
}

function print_usage() {
  $cmd = basename(__FILE__);
  echo 'usage: ' . $cmd . " [OPTIONS] FILES_AND_DIRS... DEST\n";
  echo "Copy an albums to the mp3 plauyer, performing renames to make it work.  Copy is always recursive.\n";

  echo "\nOptions:\n";
  echo "  -o  overwrite existing files.\n";
  echo "  -v  verbose output.\n";
  echo "  -h  this message and quit.\n";
}

function correct_filename($f) {
  return str_replace(' ', '.', $f);
}

/** copies a single file **/
function copy_file($src, $dest, $overwrite = false) {
  GLOBAL $VERBOSE;

  if (is_dir($dest)) {
    $dest .= correct_filename(basename($src));
  }
  else if (file_exists($dest) && ! $overwrite) {
    errln("File exists: '$dest'");
    return;
  }
  else if (strrchr($src, ".") != ".mp3") {
    errln("Ignoreing non-mp3: '$dest'");
    return;
  }

  if ($VERBOSE) dbg("Cp: $src -> $dest");
  if (! copy($src, $dest)) {
    errln("Could not copy '$src' to '$dest'.");
  }
}

/** copies a file or a directory **/
function do_copy($src, $dest, $overwrite = false) {
  GLOBAL $VERBOSE;

  if (! is_dir($src)) {
    copy_file($src, $dest, $overwrite);
  }
  else {
    $src = format_dir($src);
    $files = get_file_list($src, GET_FILE_LIST_ALL);

    if ($files === NULL) {
      errln("Error: couldn't open dir: $src.");
    }
    else if (sizeof($files) == 0) {
      errln("Warning: no files in dir: $src.");
    }
    else {
      if (is_dir($dest)) {
        $dest_dir = $dest . format_dir(correct_filename(basename($src)));
      }
      else {
        $dest_dir = format_dir(correct_filename($dest));
      }

      if ($VERBOSE) dbg("Mkdir: " . $dest_dir);

      if (! mkdir($dest_dir)) {
        errln("Unable to make '" . $dest_dir . "'");
        return 1;
      }

      foreach ($files as $f) {
        do_copy($src . $f, $dest_dir . correct_filename($f), $overwrite);
      }

      return 0;
    }
  }
}

$OPT = getopt("hov");

if (isset($OPT['h'])) {
  print_usage();
  exit(0);
}
if ($argc <= 1) {
  errln("No arguments given.");
  print_usage();
  exit(1);
}
else if ($argc <= 2) {
  errln("Not enough arguments - no destination.");
  print_usage();
  exit(1);
}

$VERBOSE = isset($OPT['v']);
$DEST = format_dir($argv[$argc-1]);
$OVERWRITE = isset($OPT['o']);
if ($argc >= 3 && ! is_dir($DEST)) {
  errln("Multiple arguments given, but the destination is not a directory (" . $DEST .").");
  exit(1);
}

$end = $argc - 1;
for ($i = 1; $i < $end; ++$i) {
  if (! file_exists($argv[$i])) {
    errln("Source does not exist: " . $argv[$i] . ".");
  }
  else {
    do_copy($argv[$i], $DEST, $OVERWRITE);
  }
}




