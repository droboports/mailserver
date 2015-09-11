<?php 
$app = "mailserver";
$appname = "Modoboa";
$appversion = "1.0.1";
$appsite = "http://modoboa.org/";
$apphelp = "http://modoboa.org/en/support/";

$applogs = array("/tmp/DroboApps/".$app."/log.txt",
                 "/tmp/DroboApps/".$app."/dovecot.log",
                 ":/bin/grep postfix /var/log/messages");

$appprotos = array("http", "tcp", "tcp", "tcp", "tcp", "tcp", "tcp", "tcp");
$appports = array("8000", "25", "110", "143", "465", "587", "993", "995");
$droboip = $_SERVER['SERVER_ADDR'];
$apppage = $appprotos[0]."://".$droboip.":".$appports[0]."/";
if ($publicip != "") {
  $publicurl = $appprotos[0]."://".$publicip.":".$appports[0]."/";
} else {
  $publicurl = $appprotos[0]."://public.ip.address.here:".$appports[0]."/";
}
$portscansite = "http://mxtoolbox.com/SuperTool.aspx?action=scan%3a".$publicip."&run=toolpage";
$blacklistsite = "http://mxtoolbox.com/SuperTool.aspx?action=blacklist%3a".$publicip."&run=toolpage";
$mxsite = "http://mxtoolbox.com/";
$dnssite = "https://toolbox.googleapps.com/apps/checkmx/";
?>