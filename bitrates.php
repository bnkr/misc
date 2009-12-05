#!/usr/bin/php
<?php
require_once("blib/texttools.php");
require_once("blib/files.php");
require_once("/home/bunker/src/piracy_helper/getid3/getid3.php");

define("MIN_BITRATE", 192000);
define("MIN_SAMPLERATE", 44100);

function max_strlen($v) {
  return texttools_max_strlen($v);
}

function print_usage() {
  echo basename($_SERVER['PHP_SELF']) . " DIRS.\n";
}

if ($argv[1] == "" || $argv[1][0]  == "-") {
  print_usage();
  exit(1);
}

function album_bitrates($dir) {
  if (substr($dir, -1) != "/") $dir .= "/";

  $exts = array(".mp3", ".ogg");
  $files = get_file_list($dir, GET_FILE_LIST_FILES, $exts);

  if ($files === NULL) {
    fwrite(STDERR, "Error: can't open directory $dir.\n");
    return;
  }

  if (sizeof($files) == 0) {
    fwrite(STDERR, "Error: no files in directory $dir.\n");
    return;
  }

  sort($files);
  $text = "Directory: $dir...\n";
  $max_file_len = max_strlen($files);
  foreach ($files as $f) {
    if (substr($f, 0, 1) != "_") {
      $text .= file_bitrate($dir . $f, $max_file_len);
    }
  }
  echo $text;
}

function file_bitrate($path, $max_file_len) {
  GLOBAL $id3;
  STATIC $err_style = array('fg' => TT_COL_LTRED);

  $f = basename($path);

  try {
    $data = $id3->Analyze($path);
  }
  catch (Exception $e) {
    echo 'Exception caught on file ' . $f . ": " . $e->getMessage() . "\n";
    return;
  }

  #dbg_buff('print_r', array(&$data['audio']));

  $text = "";

  $text .= str_pad($f, $max_file_len, " ", STR_PAD_RIGHT) . " ";

  $chan_str = str_pad($data['audio']['channelmode'], 6, " ", STR_PAD_RIGHT) . " ";
  if ($data['audio']['channelmode'] != 'stereo') {
    $bitrate_string = texttools_apply_style($chan_str, $err_style);
  }
  $text .= $chan_str;

  $text .= str_pad($data['audio']['dataformat'], 3, " ", STR_PAD_RIGHT) . " ";

  $sr_string = str_pad($data['audio']['sample_rate'] . "hz", 8, " ", STR_PAD_RIGHT) . " ";
  if ($data['audio']['sample_rate'] < MIN_SAMPLERATE) {
    $sr_string = texttools_apply_style($sr_string, $err_style);
  }
  $text .= $sr_string;

  $bitrate_string = round($data['audio']['bitrate'] / 1000) . "kb/s " . $data['audio']['bitrate_mode'];
  $bitrate_string = str_pad($bitrate_string, 12, " ", STR_PAD_RIGHT) . " ";
  if ($data['audio']['bitrate'] < MIN_BITRATE) {
    $bitrate_string = texttools_apply_style($bitrate_string, $err_style);
  }
  $text .= $bitrate_string;

  if ($data['audio']['codec'] != "") {
    $text .= "encoded in " . $data['audio']['codec'] . " ";
    if ($data['audio']['encoder'] != "") $text .= "by " . $data['audio']['encoder'];

  }
  $text .= "\n";

  return $text;
}

$id3 = new getid3();

for ($i = 1; $i < $argc; ++$i) {
  if (is_dir($argv[$i])) {
    album_bitrates($argv[$i]);
  }
  else {
    echo file_bitrate($argv[$i], 0);
  }
}
?>
