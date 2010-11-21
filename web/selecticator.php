<?php
define('API_SEARCH_QVAR', 'search');
$API_SEARCH_ERROR = false;
$API_SEARCH_SITES = array();

function api_search_site($id, $button, $url) {
  GLOBAL $API_SEARCH_SITES;

  $data = array(
    'button' => $button,
    'url' => $url
    );

  $API_SEARCH_SITES[$id] = $data;
}

function api_search_site_google($id, $button, $site) {
  api_search_site($id, $button, "http://www.google.co.uk/search?q=site:" . urlencode($site) . " ");
}

function api_search_print_form() {
  GLOBAL $API_SEARCH_SITES, $API_SEARCH_ERROR;

  echo '<form method="post" action="' . $_SERVER['SCRIPT_NAME'] . "\"><p>\n";
  $fvalue = (isset($_REQUEST[API_SEARCH_QVAR])) ? $_REQUEST[API_SEARCH_QVAR] : "";
  echo "  <input name=\"" . API_SEARCH_QVAR . "\" value=\"" . $fvalue . "\" size=\"30\" type=\"text\" />\n";
  foreach ($API_SEARCH_SITES as $id => $site) {
    echo "  <input type=\"submit\" name=\"" . $id . "\" value=\"" . $site['button'] . "\" />\n";
  }
  if ($API_SEARCH_ERROR) echo "There was some form of error with that request.<br/>";
  echo "</p></form>";
}

function api_search_redirect() {
  GLOBAL $API_SEARCH_SITES, $API_SEARCH_ERROR;

  if (isset($_REQUEST[API_SEARCH_QVAR])) {
    foreach ($API_SEARCH_SITES as $id => $stuff) {
      if (isset($_REQUEST[$id])) {
        header("location: " . $stuff['url'] . urlencode($_REQUEST[API_SEARCH_QVAR]));
        exit(0);
      }
    }

    // if we got this far the input wasn't in the array... bummer
    $API_SEARCH_ERROR = true;
  }
  else {
    header("Last-Modified: " . gmdate('D, d M Y H:i:s', filemtime(__FILE__)));
  }
}

api_search_site('google', 'Google', 'http://www.google.co.uk/search?q=');
api_search_site_google("cstdlib", "C++ Ref", "www.cplusplus.com/reference/");
api_search_site_google("haskell", "Haskell", "haskell.org/ghc/dist/current/docs/html/libraries");
api_search_site('php', "PHP", "http://php.net/search.php?show=quickref&pattern=");
api_search_site_google('qt', 'Qt', 'doc.trolltech.com/4.4');
api_search_site_google('python', 'Python', 'docs.python.org/lib/');
api_search_site_google('ruby', 'Ruby', 'www.ruby-doc.org/');

api_search_redirect();

?><!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN"
   "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
<head>
  <meta http-equiv="content-type" content="text/html;charset=utf-8" />
  <title>The Selecticator V4.1 - Back To The Oldskool</title>
<style type="text/css">
  <!--

body, table {
  background-color: #ffffff;
  font-family: Tahoma, Verdana, sans-serif;
  font-size: 10pt;
}

a:link {color: #005A9C; text-decoration: underline}
a:visited {color: #005A9C; text-decoration: underline}
a:active {color: #005A9C; text-decoration: none}
a:hover {color: #DFEBF7; background-color: #005A9C; text-decoration: none}

h1, h2 {
  color: #005A9C;
}

div.section {
  background-color: #EAF5FF;
  border: 1px #005A9C solid;
  margin-top: 10px;
  margin-bottom: 10px;
  margin-left: 20%;
  margin-right: 20%;
}

div.section > h2 {
  border-bottom: 1px #005A9C solid;
  background-color: #DFEBF7;
  font-size: 16pt;
  line-height: 16pt;
  margin: 0px;
  padding: 3px;

}


div.section > p {
  padding: 1px;
  margin: 2px;
}

input {
  border: 1px #005A9C;
  border-style: solid;
  color: #005A9C;
  background-color: #DFEBF7;
}

input[type="submit"], input[type="text"] {
  font-size: 8pt;
}


  -->
</style>
</head>
<body style="text-align:center">
<h1 style="margin: 0px; padding: 0px">The Selecticator</h1>
<div class="section">
  <h2>Games</h2>
  <p>
    <a href="http://www.nationstates.net/">NationStates</a> |
    <a href="http://www.armorgames.com/">Armor Games</a><br/>
    <a href="http://fragmasters.hlstatsx.com/?game=tf">Chavmasters TF2</a> |
    <a href="http://stats.gtfogaming.co.uk/tf">GTFO TF2</a>
    <!--<a href="http://stats.gtfogaming.co.uk/hlstats.php?mode=servers&server_id=3&game=tf">GTFO TF2</a>-->
  </p>
</div>

<div class="section">
  <h2>Local</h2>
  <p>
    <a href="http://localhost/projects/bunkerprivate/gitweb/">GitWeb</a>
    | <a href="http://localhost/projects/bunkerprivate/gitweb/?o=age">GitWeb by Age</a>
    | <a href="http://localhost/projects/bunkerprivate/projects">Projects Page</a><br/>
    <a href="http://localhost/projects/">Local Web Projects</a><br/>
    <a href="http://localhost/cgi-bin/man/man2html">Manpages</a> |
    <a href="file:///usr/share/doc/">Local Docs</a><br/>
  </p>
</div>

<div class="section">
  <h2>Programming</h2>
    <?php api_search_print_form(); ?>
  <p>
    <a href="deframe.php?url=http://www.ruby-doc.org/core/fr_class_index.html">Ruby Classes</a> |
    <a href="deframe.php?url=http://www.ruby-doc.org/core/fr_method_index.html">Ruby Methods</a> |
    <a href="http://gcc.gnu.org/onlinedocs/libstdc++/latest-doxygen/hierarchy.html">C++ Classes</a>
    (<a href="http://gcc.gnu.org/onlinedocs/libstdc++/manual/spine.html">Doc</a>) |
    <a href="http://java.sun.com/j2se/1.5.0/docs/api/allclasses-frame.html">Java Classes</a><br/>
    <a href="http://www.php.net/">PHP.net</a> | <a href="http://www.ruby-lang.org/">Ruby Lang</a><br/>
    <a href="http://www.w3.org/TR/html401/">HTML 4.01 Spec</a> | <a href="http://www.w3.org/Style/CSS/">CSS</a><br/>
    <a href="http://validator.w3.org/">W3C HTML/CSS Validator</a>
  </p>
</div>

<div class="section">
  <h2>Stuff</h2>
  <p>
    <a href="https://slashdot.org/">Slashdot</a> | <a href="http://news.google.co.uk">Google News (UK)</a><br/>
    <a href="http://www.fazed.org/">Fazed</a><br/>
    <a href="http://www.boredatwork.com/">Bored At Work</a><br/>
    <a href="http://www.boingboing.net/">Boing Boing</a><br/>
    <a href="http://www.maddox.xmission.com/">Maddox</a><br/>
  </p>
</div>

<div class="section">
  <h2>Comics</h2>
  <p>
    <a href="http://www.questionablecontent.net/">Questionable Content</a> |
    <a href="http://www.overcompensating.com/">Over Compensating</a> |
    <a href="http://www.xkcd.com/">XKCD</a> |
    <a href="http://www.daniellecorsetto.com/gws.html">GWS</a><br/>
    <a href="http://www.homestarrunner.com/">Homestar Runner</a><br/>
    <a href="http://www.purepwnage.com/">Pure Pwnage</a><br/>
    <a href="http://www.weebls-stuff.com/">Weebl's Stuff</a><br/>
    <a href="http://www.escapistmagazine.com/videos/view/zero-punctuation">Zero Punctutation</a><br/>
  </p>
</div>

<div class="section">
  <h2>Sites</h2>
  <p>
    Lukehost:
    <a href="https://srv1.uniqueicthosting.com:2083/frontend/x2/index.html">Cpanel</a> |
    <a href="https://srv1.uniqueicthosting.com:2083/3rdparty/phpMyAdmin/index.php">phpMyAdmin</a> |
    <a href="http://www.bananadine.co.uk/admin/news.php">Dine Admin</a><br/>

    <a href="http://registrar.godaddy.com/">GoDaddy</a> |
    <a href="http://123-reg.co.uk/">123-Reg</a><br/>

    <a href="http://www.bananadine.co.uk/">bananadine.co.uk</a> |
    <a href="http://www.bunkerprivate.com/">bunkerprivate.com</a> |
    <a href="http://www.lornawebber.com/">lornawebber.com</a> |
    <a href="http://www.arghness.com/">arghness.com</a><br/>
  </p>
</div>

<div class="section">
  <h2>Tech Review</h2>
  <p>
    <a href="http://www.arstechnica.com/">Arstechnica</a><br/>
    <a href="http://www.anandtech.com/">Anandtech</a><br/>
    <a href="http://www.tomshardware.com/">Tom's Hardware</a><br/>
    <a href="http://www.xbitlabs.com/">X-bit Labs</a><br/>
    <a href="http://www.hexus.net/">Hexus</a><br/>
  </p>
</div>

<div class="section">
  <h2>Shops</h2>
  <p>
    <a href="http://www.ebay.co.uk/">eBay (UK)</a> | <a href="http://my.ebay.co.uk/">My eBay</a><br/>
    <a href="http://www.amazon.co.uk/">Amazon (UK)</a> | <a href="http://www.ebuyer.co.uk/">eBuyer</a><br/>
    <a href="http://www.aria.co.uk/">Aria</a> | <a href="http://www.komplett.co.uk/">Komplett</a>
  </p>
</div>

<div class="section">
  <h2>"Shops"</h2>
  <p>
    <a href="http://www.mininova.org/">Mininova</a><br/>
    <a href="http://www.thepiratebay.org/">The Pirate Bay</a><br/>
    <a href="http://www.isohunt.com/">IsoHunt</a><br/>
    <a href="http://www.ircspy.com/">IRCSpy</a><br/>
  </p>
</div>

<div class="section">
  <h2>Debian</h2>
  <p>
    <a href="http://bjorn.haxx.se/debian/testing.pl">Why is X not in Testing?</a><br/>
    <a href="http://packages.debian.org/">Packages Search</a><br/>
  </p>
</div>

<div class="section">
  <h2>Services</h2>
  <p>
    <a href="https://mail.google.com/mail/#inbox">Google Mail</a><br/>
    <a href="http://news.bbc.co.uk/weather/forecast/2818?area=RG3&state=fo:B#fo:B">BBC Reading Weather</a>
  </p>
</div>
</body>
</html>
