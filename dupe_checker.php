#!/usr/bin/php
<?php
/// TODO:
///   say directly the dir is a duplicate - as in dir x is a complete dupe of dir y, not just files.

require_once("blib/debug.php");
require_once("blib/files.php");

$hashes = array();
$dupfound = 0;
$files_scanned = 0;

function get_hashes($dir) {
  GLOBAL $hashes, $dupfound, $files_scanned;
  
  if (substr($dir, -1) != "/") $dir .= "/";
  
  $files = get_file_list($dir, GET_FILE_LIST_FILES);
  if ($files !== NULL) {
    $files_in_this_dir = 0;
    $matches = 0;
    
    foreach ($files as $f) {
      $path = $dir . $f;
      $hash = md5_file($path);
      ++$files_in_this_dir;
      ++$files_scanned;
      if (isset($hashes[$hash])) {
        ++$dupfound;
        ++$matches;
        echo $path . " is a duplicate of " . $hashes[$hash] . "\n";
      }
      else {
        $hashes[$hash] = $path;
      }
    }
    
    // skip dirs with nothing in it
    if ($matches != 0) {
      if ($matches != $files_in_this_dir) {
        echo "Warning!  Not all files in $dir are duplicates.\n";
      }
      else {
        echo "All files in $dir are duplicated elsewhere.\n";
      }
    }
  }
  else {
    echo "Error opening $dir.\n";
  }
}
  
if ($argc > 1) {
  for ($i = 1; $i < $argc; ++$i) {
//     dbg($argv[$i]);
    get_hashes($argv[$i]);
  }
}
else {
  get_hashes("./");
}

echo $dupfound . " duplicates found of " . $files_scanned . " files scanned.\n";
