#!/usr/bin/php
<?php
require_once('blib/texttools.php');

// fuck php.
function title_case($a) { return texttools_title_case($a); }

function print_usage() {
  $bin = basename($_SERVER['PHP_SELF']);
  echo $bin . " [-s] [-r REMOVE] [-d DIRNAME] [-i]\n";

  $pad = '  ';
  echo "Options:";
  echo $pad . "-h         print this message and exit.\n";
  echo $pad . "-s         just print renames (simulate).\n";
  echo $pad . "-i         ignore files that don't match the guessed format.\n";
  echo $pad . "-r REMOVE  remove the specified string from each filename.  The\n";
  echo $pad . "           removed string is NOT included when detecting music files\n";
  echo $pad . "           (meaning -r '.mp3' should work.) Seperate multiple strings\n";
  echo $pad . "           with commas.\n";
  echo $pad . "-d DIRNAME name of directory containing files (default pwd)\n";
}


function format_dir($s) {
  if (substr($s, -1) != '/') $s .= '/';
  return $s;
}

// defaults
$simulate = false;
$remove   = "";
$dir      = getcwd();

$OPTIONS = getopt("sr:hid:");

$long_help = false;
foreach ($argv as $arg) {
  if (substr($arg, 0, 3) == "--h") {
    $long_help = true;
  }
}

if (isset($OPTIONS['h']) || $long_help) {
  print_usage();
  exit(0);
}

if (isset($OPTIONS['s'])) {
  echo "Pretending to rename...\n";
  $simulate = true;
}
else {
  $simulate = false;
}

$remove = isset($OPTIONS['r']) ? explode(",", $OPTIONS['r']) : null;


if (isset($OPTIONS['d'])) {
  $dir = $OPTIONS['d'];
}
else {
  $dir = '.';
}

$exts = array(".mp3", ".m4a", ".ogg", ".avi");


if ($remove) {
  $rems = "'" . implode("', '", $remove) . "'";
  echo "Will remove: ${rems}\n";
}


// program
$dir = format_dir($dir);
if (! $dh = opendir($dir)) {
  fwrite(STDERR, "Error: could not open '" . $dir . "'.\n");
  exit(1);
}
else {
  $files = array();
  while (($file = readdir($dh)) !== false) {
    if ($file[0] != "." && in_array(strrchr($file, '.'), $exts)) {
      $files[] = $file;
    }
  }

  if (count($files) == 0) {
    fwrite(STDERR, "Error: no media files in directory '" . $dir . ".'\n");
    exit(1);
  }

  // Enumerate ID's for our naming schemes
  define('NS_COMPACT', 0);
  define('NS_NODASH' , 1);
  define('NS_TRDOT',   2);
  define('NS_TRDASH',  3);
  define('NS_MYOLD',   4);
  define('NS_SMALL_COMPACT', 5);
  define('NS_COMPACT_NO_ALB', 6);

  $textfield_regexp_spaces = "[,.a-zA-Z0-9_\\(\\) \\[\\]']+";
  $textfield_regexp = "[,.a-zA-Z0-9_\\(\\)\\[\\]']+";
  $ext_regexp = "";

  // note that all of these are tested, so if multiple match you're gunna be in trouble :)
  $typereg = array(
    NS_COMPACT => '/^[0-9]+-' .$textfield_regexp. '-' . $textfield_regexp . '\\.[a-zA-Z0-9]{3}$/', // tr-something-multi_word_field.mp3
    NS_NODASH  => '/^[0-9]{1,2}\\s[^-][a-zA-Z0-9 \\-]+\\.[a-zA-Z0-9]{3}$/', // tr trackname.mp3
    NS_TRDOT   => '/^[0-9]{1,2}\\.\\s?[a-zA-Z0-9 \\-]+\\.[a-zA-Z0-9]{3}$/', // tr. trackname.mp3
    NS_TRDASH  => '/^[0-9]{1,2} - [a-zA-Z0-9 \\-]+\\.[a-zA-Z0-9]{3}$/', // tr - trackname.mp3
    NS_MYOLD   => '/^' . $textfield_regexp_spaces . '?( - )' . $textfield_regexp_spaces . '?( - )[0-9]{1,2} - ' .
        $textfield_regexp_spaces . '?\\.[a-zA-Z0-9]{3}$/',
    NS_SMALL_COMPACT => '/^[0-9]{1,2}_' . $textfield_regexp . '\\.[a-zA-Z0-9]{3}$/',
    NS_COMPACT_NO_ALB => '/^[0-9]{2}(\\.|-)' . $textfield_regexp_spaces . '\\.[a-zA-Z0-9]{3}/'
  );

  $typename[NS_COMPACT] = "Compact name ('tr-album-track_name.ext')";
  $typename[NS_COMPACT_NO_ALB] = "Compact with no album (tr<.|->track name.ext)";
  $typename[NS_NODASH]  = "Numbered with no dash ('num track name.ext')";
  $typename[NS_TRDOT]   = "Numbered with a dot ('num. track name.mp3')";
  $typename[NS_TRDASH]  = "Numbered with a dash ('num - track name.mp3')";
  $typename[NS_MYOLD]   = "My old one artist ('album - num - track name.ext')";
  $typename[NS_SMALL_COMPACT] = "Name and number with underscores (tr_track_name.ext)";

  // Find the current name scheme
  $type[NS_COMPACT] = 0;
  $type[NS_NODASH]  = 0;
  $type[NS_TRDOT]   = 0;
  $type[NS_TRDASH]  = 0;
  $type[NS_MYOLD]   = 0;
  $type[NS_SMALL_COMPACT] = 0;

  // so we can later ignore tracks which aren't matching our prefered one
  $matches = array();

  foreach ($files as $fnum => $f) {
    if ($remove != null) $f = str_replace($remove, "", $f); // hacky to do this here as well as elsewheres

    $foundmatch = false;
    foreach ($typereg as $id => $reg) {
      if (preg_match($reg, $f)) {
        $matches[$fnum][$id] = true;
        $type[$id]++;
        $foundmatch = true;
        //break;
      }
    }

    if (! $foundmatch) fwrite(STDERR, "Warning: unable to match name scheme on $files[$fnum].\n");
  }

  // Pick the most likely scheme
  $num = -1;
  $max = -1;
  foreach ($type as $i => $t) {
    if ($t > $max && $t != 0) { // != 0 so we don't assign anything if nothing matched
      $num = $i;
      $max = $t;
    }
  }

  if ($num == -1) {
    fwrite(STDERR, "Error: unable to find a probable name scheme.\n");
    exit(1);
  }

  echo "Picked most likely name scheme as #$num - $typename[$num]\n";

  // Deal with each type
  if ($num == NS_COMPACT) {
    foreach ($files as $i => $f) {
      if (isset($OPTIONS['i']) && ! $matches[$i][$num]) {
        $files_new[$i] = $f;
      }
      else {
        if ($remove != null) $f = str_replace($remove, "", $f);

        $parts = explode("-", $f, 3);

        $files_new[$i] = substr(str_pad($parts[0], 2, "0", STR_PAD_LEFT), -2) . " - ";
        $files_new[$i] .= title_case(str_replace("_", " ", $parts[2]));
      }
    }
  }
  else if ($num == NS_NODASH) {
    foreach ($files as $i => $f) {
      if (isset($OPTIONS['i']) && ! $matches[$i][$num]) {
        $files_new[$i] = $f;
      }
      else {
        if ($remove != null) $f = str_replace($remove, "", $f);

        $parts = explode(" ", $f, 2);
        $files_new[$i] = str_pad($parts[0], 2, "0", STR_PAD_LEFT) . " - " . title_case($parts[1]);
      }
    }
  }
  else if ($num == NS_TRDOT) {
    foreach ($files as $i => $f) {
      if (isset($OPTIONS['i']) && ! $matches[$i][$num]) {
        $files_new[$i] = $f;
      }
      else {
        if ($remove != null) $f = str_replace($remove, "", $f);

        $parts = explode(".", $f, 2);
        $files_new[$i]  = trim(str_pad($parts[0], 2, "0", STR_PAD_LEFT)) . " - " . trim(title_case($parts[1]));
      }
    }
  }
  else if ($num == NS_TRDASH) {
    foreach ($files as $i => $f) {
      if (isset($OPTIONS['i']) && ! $matches[$i][$num]) {
        $files_new[$i] = $f;
      }
      else {
        if ($remove != null) $f = str_replace($remove, "", $f);

        $parts = explode(" - ", $f, 2);
        $files_new[$i]  = str_pad($parts[0], 2, "0", STR_PAD_LEFT) . " - " . title_case($parts[1]);
      }
    }
  }
  else if ($num == NS_MYOLD) {
    foreach ($files as $i => $f) {
      if (isset($OPTIONS['i']) && ! $matches[$i][$num]) {
        $files_new[$i] = $f;
      }
      else {
        if ($remove != null) $f = str_replace($remove, "", $f);

        $parts = explode(" - ", $f);
        $files_new[$i]  = str_pad($parts[2], 2, "0", STR_PAD_LEFT) . " - " . title_case($parts[3]);
      }
    }
  }
  else if ($num == NS_SMALL_COMPACT) {
    foreach ($files as $i => $f) {
      if (isset($OPTIONS['i']) && ! $matches[$i][$num]) {
        $files_new[$i] = $f;
      }
      else {
        if ($remove != null) $f = str_replace($remove, "", $f);

        $parts = explode("_", $f, 2);
        $parts[1] = str_replace('_', ' ', $parts[1]);
        $files_new[$i]  = str_pad($parts[0], 2, "0", STR_PAD_LEFT) . " - " . title_case($parts[1]);
      }
    }
  }
  else if ($num == NS_COMPACT_NO_ALB) {
    foreach ($files as $i => $f) {
      if (isset($OPTIONS['i']) && ! $matches[$i][$num]) {
        $files_new[$i] = $f;
      }
      else {
        if ($remove != null) $f = str_replace($remove, "", $f);

        $tr = substr($f, 0, 2);
        $tt = str_replace('_', ' ', substr($f, 3));
        $files_new[$i]  = str_pad($tr, 2, "0", STR_PAD_LEFT) . " - " . title_case($tt);
      }
    }
  }
  else {
    fwrite(STDERR, "Error: code $num is not an existing code!\n");
    exit(1);
  }

  // keep keys, just in case
  asort($files);
  asort($files_new);

  $maxlen = -1;
  foreach ($files as $f) {
    $l = strlen($f);
    if ($l > $maxlen) $maxlen = $l;
  }

  foreach ($files as $i => $f) {
    echo str_pad($files[$i], $maxlen, " ", STR_PAD_RIGHT) .
         " => " . $files_new[$i] . "\n";

    if (! $simulate) {
      rename($dir . $files[$i], $dir . $files_new[$i]);
    }
  }
}
?>
