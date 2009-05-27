#!/usr/bin/php
<?php

/// \todo When every input dir has a number on the end, try and make an
///       output dir which doesn't have one.  Eg, in = {d1,d2,d3} =>
///       out = d.  Perhaps a mode like --name-prefix=whatever
///
/// \todo append 0 onto the file names so the numbers are all the same
///       length.  Offer an option to explicitly append a number of
///       zeros.
///
/// \todo append should work on non-empty output directories if specified
///
/// \todo -D option will not rename directories; just move them... maybe
///       have a seperate array of directory moves.

error_reporting(E_ALL);

require_once("blib/cmdline.php");
require_once("blib/files.php");

function make_directory($d) {
  GLOBAL $PRETEND, $VERBOSE;

  $mkdir_p = true;
  if (! $PRETEND) {
    $ret = mkdir($d, 0777, $mkdir_p); // modified by umask

    if (! $ret) {
      cmd_errln("error: couldn't make output directory '$OUTPUT'.");
      return null;
    }
    else {
      return $d;
    }
  }
  else {
    if ($VERBOSE) {
      cmd_outln("only pretending to make '$d'.");
    }
    return $d;
  }

}

function create_output_directory($dir, $name_is_required) {
  GLOBAL $VERBOSE, $DIRS;
  $dir = format_dir($dir);
  if (in_array($dir, $DIRS)) {
    cmd_errln("error: output directory '$dir' is also an input directory.");
    return null;
  }

  if (file_exists($dir)) {
    if (is_dir($dir)) {
      $empty = dir_empty($dir);

      if ($name_is_required && ! $empty) {
        cmd_errln("error: output directory '$dir' already exists and is nonempty.");
        return null;
      }

      if (! $empty) {
        $dir = generate_valid_name($dir);
        return make_directory($dir);
      }
      else {
        if ($VERBOSE) {
          cmd_outln("notice: using an existing empty directory '$dir'.");
        }
        return $dir;
      }
    }
    // ! is_dir
    else {
      if ($name_is_required) {
        cmd_errln("error: output directory '$dir' is a file.");
        return null;
      }
      else {
        $dir = generate_valid_name($dir);
        return make_directory($dir);
      }
    }
  }
  else {
    return make_directory($dir);
  }

}

//! Assumes it already exists.
function generate_valid_name($file) {
  GLOBAL $VERBOSE;

  $tries = 0;
  $trylimit = 50;
  $file .= ".0";
  while (file_exists($file)) {
    if ($VERBOSE) {
      cmd_outln("file '$file' already exists; trying another.");
    }

    ++$dir[strlen($file) - 1];
    ++$tries;
    if ($tries > $trylimit) {
      cmd_errln("error: too many tries to find a unique name for the output directory!");
      return null;
    }
  }

  return $file;
}

//! \todo  Not used anymore, but could be nice to resurrect this mode.
function merge_file($from_dir, $file, $to_dir) {
  GLOBAL $VERBOSE, $PRETEND, $FIND_UNIQUE_NAMES;

  // So we can exit early on colisions
  /// TODO: could be implemented better.
  static $simulated_destination = array();

  $from_name = format_dir($from_dir) . $file;
  $to_name = format_dir($to_dir) . $file;

  if (($PRETEND && isset($simulated_destination[$to_name])) || (! $PRETEND && file_exists($to_name))) {
    if ($FIND_UNIQUE_NAMES) {
      $to_name = generate_valid_name($to_name);
    }
    else {
      cmd_errln("error: file '$to_name' already exists.");
      return false;
    }
  }

  if ($PRETEND) {
    $simulated_destination[$to_name] = true;
  }

  perform_merge($from_name, $to_name);

  return true;
}

//! Move $from to $to; delete where appropriate (unless $from a directory);
function perform_merge($from, $to) {
  GLOBAL $VERBOSE, $PRETEND,  $DELETE, $MOVE_DIRECTORIES;

  if (is_dir($from) && ! $MOVE_DIRECTORIES){
    if ($VERBOSE) cmd_outln("notice: ignoring '$from' as it's a directory.");
    return;
  }

  if ($VERBOSE) {
    cmd_outln("merge: $from -> $to");
  }

  if ($PRETEND) return;

  $ret = copy($from, $to);
  if (! $ret) {
    cmd_errln("error: failed to copy '$from' to '$to'.");
    exit(1);
  }

  if ($DELETE && ! is_dir($from)) {
    $ret = unlink($from);
    if (! $ret) {
      cmd_errln("warning: couldn't delete old file '$from'.");
    }
  }
}

define('SORT_TYPE_NATSORT', 1);
define('SORT_TYPE_NORMAL', 2);

$OPTS = getopt("ho:vpatcdD");

if (isset($OPTS['h'])) {
  cmd_outln("Usage:" . $argv[0] . " [options]... dirs");
  cmd_outln("Merges two or more directories.");
  cmd_outln("");
  cmd_outln("  -h    this message and quit.");
  cmd_outln("  -o F  name of directory to output to; default is to pick the first dir and append '-merged'.");
  cmd_outln("        There will always be an error if you chose a directory and it is nonempty.");
  cmd_outln("  -v    verbose.");
  cmd_outln("  -p    pretend.");
  cmd_outln("  -a    simply append files to the directory; names are still resequenced.  Otherwise files are");
  cmd_outln("        interleaved to preserve their order, eg outputdir = {1 = 01 from d1, 2 = 01 from dir2, ...}.");
  cmd_outln("  -t    use the trivial string-based sort instead of a natural one.");
  cmd_outln("  -c    exit if there are name colisions instead of renaming.");
  cmd_outln("  -D    move directories as well (dirs will be named as part of the sequence).");
  cmd_outln("  -d    delete old files (perform a move instead of a copy.");
  cmd_outln("");
  cmd_outln("Anything begining with a dash is assumed to be a paramter, so prefix directories");
  cmd_outln("beginning with dash with './'");
  cmd_outln("");
  cmd_outln("With only one input directory, this program works as a sort-and-rename.");
  exit(0);
}

$PRETEND = isset($OPTS['p']);
$VERBOSE = isset($OPTS['v']);
$OUTPUT = (isset($OPTS['o'])) ? $OPTS['o'] : null;
$SORT_TYPE = (isset($OPTS['t'])) ? SORT_TYPE_NORMAL : SORT_TYPE_NATSORT ;
$INTERLEAVE = (! isset($OPTS['a']));
$DIRS = array();
$FIND_UNIQUE_NAMES = (! isset($OPTS['c']));
$DELETE = (isset($OPTS['d']));
$MOVE_DIRECTORIES = (isset($OPTS['D']));

if ($VERBOSE) {
  if ($SORT_TYPE == SORT_TYPE_NATSORT) {
    cmd_outln("info: using natural sort");
  }
  else if ($SORT_TYPE == SORT_TYPE_NORMAL) {
    cmd_outln("info: using normal sort");
  }
}

for ($i = 1; $i < $argc; ++$i) {
  if ($argv[$i][0] != '-') {

    if (in_array($argv[$i], $DIRS)) {
      cmd_errln("warning: duplicate dir '${argv[$i]}' ignored.");
    }
    else {
      $DIRS[] = format_dir($argv[$i]);
      if ($VERBOSE) {
        cmd_outln("info: input directory: '${argv[$i]}'.");
      }
    }
  }
  else {
    if ($VERBOSE) {
      cmd_outln("info: ignoring parameter '${argv[$i]}' as a directory.");
    }

    // ignore the argument of -o
    if ($argv[$i][strlen($argv[$i]) - 1] == 'o') {
      ++$i;
    }
  }
}

if (sizeof($DIRS) == 0) {
  cmd_errln("error: no directories to merge; see -h for more.");
  exit(1);
}
else if (sizeof($DIRS) == 1) {
  if ($VERBOSE) {
    cmd_outln("notice: doing a sequence rename since there is only one input directory.");
  }
}

if ($OUTPUT != null)  {
  $OUTPUT = create_output_directory($OUTPUT, true);
  if ($OUTPUT == null) {
    exit(1);
  }
}
else {
  $OUTPUT = create_output_directory($DIRS[0] . "-mergedirs", ! $FIND_UNIQUE_NAMES);
  if ($OUTPUT == null) {
    exit(1);
  }
}

$OUTPUT = format_dir($OUTPUT);

if ($VERBOSE) {
  cmd_outln("info: otput directory will be '$OUTPUT'.");
}

// Build up a table where rows are the files and cols are the dirs they are in.
// We will traverse it by iterating over by columns first which means we can
// preserve the orignal order.

$files = array();
$total_files = 0;
foreach ($DIRS as $i => $d) {
  $fs = get_file_list(format_dir($d), GET_FILE_LIST_DIRS|GET_FILE_LIST_FILES);
  if ($fs === null) {
    cmd_errln("error: couldn't open directory '$d'.");
    exit(1);
  }

  $total_files += sizeof($fs);

  if ($VERBOSE) {
    cmd_outln("info: " . sizeof($fs) . " files in '$d'.");
  }

  if ($SORT_TYPE == SORT_TYPE_NATSORT) {
    natcasesort($fs);

    // natcasesort keeps the keys, but changes the order
    $temp = array();
    foreach ($fs as $v) {
      $temp[] = $v;
    }
    $fs = $temp;
  }
  else if ($SORT_TYPE == SORT_TYPE_NORMAL) {
    sort($fs);
  }
  else {
    cmd_errln("error: invalid sort type (that's unpossible).");
    exit(1);
  }

  $files[$i] = $fs;
}

if ($INTERLEAVE) {
  if ($VERBOSE) {
    cmd_outln("info: doing interleaving");
  }

  $number_pad_length = strlen($total_files - 1);  // because we start at 0
  $filenum = 0;
  $dest_file_number = 0;
  $dirnum = 0;
  $finished = false;
  // Traverse as though a table of columns so order is preserved.
  while (! $finished) {
    $finished = true;
    foreach ($DIRS as $dirnum => $dir) {
      if (isset($files[$dirnum][$filenum])) {
        $file = $files[$dirnum][$filenum];
        $finished = false;

        $from = format_dir($dir) . $file;
        $ext = strrchr($file, ".");

        $num_string = str_pad($dest_file_number, $number_pad_length, "0", STR_PAD_LEFT);
        $to = $OUTPUT . $num_string . $ext;

        perform_merge($from, $to);

        ++$dest_file_number;
      }
    }
    ++$filenum;
  }

  if ($VERBOSE) {
    cmd_outln("info: copied $dest_file_number files.");
  }
}
else {
  if ($VERBOSE) {
    cmd_outln("info: doing simple merge; no interleaving.");
  }

  $filenum = 0;
  $number_pad_length = strlen($total_files - 1);
  foreach ($files as $dirnum => $fs) {
    $dir = $DIRS[$dirnum];
    foreach ($fs as $file) {
      $from = $dir . $file;
      $ext = strrchr($file, '.');
      $num_string = str_pad($filenum, $number_pad_length, "0", STR_PAD_LEFT);
      $to = $OUTPUT . $num_string . $ext;

      perform_merge($from, $to);

      ++$filenum;
    }
  }

  if ($VERBOSE) {
    cmd_outln("info: copied $filenum files.");
  }
}

