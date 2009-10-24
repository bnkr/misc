#!/usr/bin/php
<?php
require_once("blib/cmdline.php");

/// \todo rewrite options using ProgramOptions.

$OPT = getopt("hs:H:m:t:M:S:q");

function cmd_stdln($p) { cmd_outln($p); }

function print_usage() {
  cmd_stdln("Usage: " . basename($_SERVER['SCRIPT_NAME']) . " [option]...");
  cmd_stdln("Wait for some time and print a message.  Kinda like an alarm clock, eh?\n");
  cmd_stdln("Options:");
  cmd_stdln("  -h    this message and quit.");
  cmd_stdln("  -s T  alarm in T secconds.");
  cmd_stdln("  -m T  alarm in T minutes.");
  cmd_stdln("  -H T  alarm in T hours.");
  cmd_stdln("  -t T  alarm at the time T (use h[:m[:s]], 24hr format).");
  cmd_stdln("  -M M  use the text M in the message dialogue when the alarm goes off.  Use \\n to denote a newline.");
  cmd_stdln("  -q    do not display a mesasge.");
  cmd_stdln("  -S F  play sound file F with mplayer.");
}

/*!
\param $msgstr     Displayed in a message box after the time is up; no box is
                   displayed if this is blank.
\param $soundfile  run with mplayer.  Again, if blank no sound file is loaded.
*/
function do_alarm($target_ts, $msgstr, $soundfile) {
  while (time() < $target_ts) {
    sleep(1);
  }

  if ($soundfile != '') {
    $pid = pcntl_fork();
    if ($pid == -1) {
      die("Teh problem.");
    }
    else if ($pid == 0) {
      system("mplayer \"" . $soundfile . "\"");
      exit(0);
    }
  }

  if ($msgstr != '') {
    system("kdialog --msgbox '" . $msgstr . "\n\nThe time has reached: " . date("H:i:s", $target_ts) . "' &");
  }

  if ($soundfile != '') {
    $stat = 0;
    pcntl_waitpid($pid, $stat);
  }
}

if (isset($OPT['h'])) {
  print_usage();
  exit(0);
}

$ADD_SEC = (isset($OPT['s'])) ? $OPT['s'] : 0;
$ADD_MIN = (isset($OPT['m'])) ? $OPT['m'] * 60 : 0;
$ADD_HRS = (isset($OPT['H'])) ? $OPT['H'] * 60 * 60 : 0;

if (isset($OPT['M'])) {
  if (isset($OPT['q'])) cmd_errln("-M was set, but so was -q!  Using specified message.");

  $MESSAGE = $OPT['M'];
}
else if (isset($OPT['q'])) {
  $MESSAGE = "";
}
else {
  $MESSAGE = "AAAALLLAAAAAARM!!!";
}

if (isset($OPT['S'])) {
  if (! file_exists($OPT['S'])) {
    cmd_errln("Error: the file '$OPT[S]' does not exist.");
    exit(1);
  }
  $SOUND = $OPT['S'];

}
else {
  $SOUND = '';
}

$total_offset = $ADD_SEC + $ADD_MIN + $ADD_HRS;

if (isset($OPT['t'])) {
  if ($total_offset != 0) {
    cmd_errln("Warning: offset params set, but the absolute time overrides it.");
  }

  $parts = explode(":", $OPT['t']);
  if (sizeof($parts) == 0) {
    cmd_errln("'" . $OPT['t'] . "' is not a vaild time.");
    print_usage();
    exit(1);
  }

  $h = $parts[0];
  $m = (isset($parts[1])) ? $parts[1] : 0;
  $s = (isset($parts[2])) ? $parts[2] : 0;

  $ts = strtotime(date("Y-m-d ") .
                  str_pad($h, "0", STR_PAD_LEFT) . ":" .
                  str_pad($m, "0", STR_PAD_LEFT) . ":" .
                  str_pad($s, "0", STR_PAD_LEFT));
  cmd_stdln("Waiting until " . date("H:i:s", $ts));
  do_alarm($ts, $MESSAGE, $SOUND);
}
else {
  $alarm_time = time() + $total_offset;
  cmd_stdln("Waiting until " . date("H:i:s", $alarm_time));
  do_alarm($alarm_time, $MESSAGE, $SOUND);
}
