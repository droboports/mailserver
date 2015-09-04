<?php
header('Cache-Control: no-store, no-cache, must-revalidate, max-age=0');
header('Cache-Control: post-check=0, pre-check=0', false);
header('Pragma: no-cache');

$app = "mailserver";
$appname = "Modoboa mailserver";
$appversion = "1.0.1";
$applogs = array("/tmp/DroboApps/".$app."/log.txt",
                 "/tmp/DroboApps/".$app."/dovecot.log",
                 ":/bin/grep postfix /var/log/messages");
$appsite = "http://modoboa.org/";
$apppage = "http://".$_SERVER['SERVER_ADDR'].":8000/";
$apphelp = "http://modoboa.org/en/support/";

$op = $_REQUEST['op'];
switch ($op) {
  case "start":
    exec("/usr/bin/DroboApps.sh start_app ".$app, $out, $rc);
    if ($rc === 0) {
      $opstatus = "okstart";
    } else {
      $opstatus = "nokstart";
    }
    break;
  case "stop":
    exec("/usr/bin/DroboApps.sh stop_app ".$app, $out, $rc);
    if ($rc === 0) {
      $opstatus = "okstop";
    } else {
      $opstatus = "nokstop";
    }
    break;
  default:
    $opstatus = "noop";
    break;
}

$publicip = shell_exec("/usr/bin/wget -qO- http://ipecho.net/plain");
$blacklistsite = "http://mxtoolbox.com/SuperTool.aspx?action=blacklist%3a".$publicip."&run=toolpage";
$mxsite = "http://mxtoolbox.com/";
$dnssite = "https://toolbox.googleapps.com/apps/checkmx/";

$out = shell_exec("/usr/bin/DroboApps.sh status_app ".$app);
if (strpos($out, "running") !== FALSE) {
  $apprunning = TRUE;
} else {
  $apprunning = FALSE;
}
?>
<!DOCTYPE html>
<html lang="en">

<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <meta http-equiv="X-UA-Compatible" content="IE=edge" />
  <meta http-equiv="cache-control" content="no-cache" />
  <meta http-equiv="expires" content="-1" />
  <meta http-equiv="pragma" content="no-cache" />
  <title><?php echo $appname; ?> DroboApp</title>
  <link rel="stylesheet" type="text/css" media="screen" href="css/bootstrap.min.css" />
  <link rel="stylesheet" type="text/css" media="screen" href="css/custom.css" />
  <script src="js/jquery.min.js"></script>
  <script src="js/bootstrap.min.js"></script>
</head>

<body>
<nav class="navbar navbar-default navbar-fixed-top">
  <div class="container-fluid">
    <div class="navbar-header">
      <a class="navbar-brand" href="<?php echo $appsite; ?>" target="_new"><img alt="<?php echo $appname; ?>" src="img/app_logo.png" /></a>
    </div>
    <div class="collapse navbar-collapse" id="navbar">
      <ul class="nav navbar-nav navbar-right">
        <li><a class="navbar-brand" href="http://www.drobo.com/" target="_new"><img alt="Drobo" src="img/drobo_logo.png" /></a></li>
      </ul>
    </div>
  </div>
</nav>

<div class="container top-toolbar">
  <div class="btn-toolbar" role="toolbar">
    <div class="btn-group" role="group">
      <p class="title">About <?php echo $appname; ?> <?php echo $appversion; ?></p>
    </div>
    <div role="group" class="btn-group pull-right">
      <?php if ($apprunning) { ?>
      <a role="button" class="btn btn-primary" href="?op=stop" onclick="$('#pleaseWaitDialog').modal(); return true"><span class="glyphicon glyphicon-stop"></span> Stop App</a>
      <a role="button" class="btn btn-primary" href="<?php echo $apppage; ?>" target="_new"><span class="glyphicon glyphicon-globe"></span> Go to App</a>
      <?php } else { ?>
      <a role="button" class="btn btn-primary" href="?op=start" onclick="$('#pleaseWaitDialog').modal(); return true"><span class="glyphicon glyphicon-play"></span> Start App</a>
      <a role="button" class="btn btn-primary disabled" href="<?php echo $apppage; ?>" target="_new"><span class="glyphicon glyphicon-globe"></span> Go to App</a>
      <?php } ?>
      <a role="button" class="btn btn-primary" href="<?php echo $apphelp; ?>" target="_new"><span class="glyphicon glyphicon-question-sign"></span> Help</a>
    </div>
  </div>
</div>

<div role="dialog" id="pleaseWaitDialog" class="modal animated bounceIn" tabindex="-1" aria-labelledby="myModalLabel" aria-hidden="true">
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-body">
        <p id="myModalLabel">Operation in progress... please wait.</p>
        <div class="progress">
          <div class="progress-bar progress-bar-striped active" aria-valuenow="100" aria-valuemin="0" aria-valuemax="100" style="width: 100%">
          </div>
        </div>
      </div>
    </div>
  </div>
</div>

<div class="container">
  <div class="row">
    <div class="col-xs-3"></div>
    <div class="col-xs-6">
<?php switch ($opstatus) { ?>
<?php case "okstart": ?>
      <div class="alert alert-success fade in" id="opstatus">
        <a href="#" class="close" data-dismiss="alert" aria-label="close">&times;</a>
        <?php echo $appname; ?> was successfully started.
      </div>
<?php break; case "nokstart": ?>
      <div class="alert alert-error fade in" id="opstatus">
        <a href="#" class="close" data-dismiss="alert" aria-label="close">&times;</a>
        <?php echo $appname; ?> failed to start. See logs below for more information.
      </div>
<?php break; case "okstop": ?>
      <div class="alert alert-success fade in" id="opstatus">
        <a href="#" class="close" data-dismiss="alert" aria-label="close">&times;</a>
        <?php echo $appname; ?> was successfully stopped.
      </div>
<?php break; case "nokstop": ?>
      <div class="alert alert-error fade in" id="opstatus">
        <a href="#" class="close" data-dismiss="alert" aria-label="close">&times;</a>
        <?php echo $appname; ?> failed to stop. See logs below for more information.
      </div>
<?php break; } ?>
      <script>
      window.setTimeout(function() {
        $("#opstatus").fadeTo(500, 0).slideUp(500, function() {
          $(this).remove(); 
        });
      }, 2000);
      </script>
    </div><!-- col -->
    <div class="col-xs-3"></div>
  </div><!-- row -->

  <div class="row">
    <div class="col-xs-12">

  <!-- description -->
  <div class="panel-group" id="description">
    <div class="panel panel-default">
      <div class="panel-heading">
        <h4 class="panel-title"><a data-toggle="collapse" data-parent="#description" href="#descriptionbody">Description</a></h4>
      </div>
      <div id="descriptionbody" class="panel-collapse collapse in">
        <div class="panel-body">
          <p><?php echo $appname; ?> is a group of apps configured to provide a fully functional email solution out of the box. This includes:</p>
          <ol>
            <li><a href="http://www.postfix.org/" target="_new">Postfix 2.10.1</a>, a free and open source SMTP server.</li>
            <li><a href="http://www.dovecot.org/" target="_new">Dovecot 2.2.5</a>, a free and open source IMAP and POP3 server.</li>
            <li><a href="http://modoboa.org/" target="_new">Modoboa 1.0.1</a>, a free and open source email management and webmail interface.</li>
          </ol>
        </div>
      </div>
    </div>
  </div>

  <!-- shorthelp -->
  <div class="panel-group" id="shorthelp">
    <div class="panel panel-default">
      <div class="panel-heading">
        <h4 class="panel-title"><a data-toggle="collapse" data-parent="#shorthelp" href="#shorthelpbody">Getting started</a></h4>
      </div>
      <div id="shorthelpbody" class="panel-collapse collapse in">
        <div class="panel-body">
          <p>To access <?php echo $appname; ?> on your Drobo click the &quot;Go to App&quot; button above.</p>
          <p>The default admin login and password are:</p>
          <form class="form-horizontal">
            <div class="form-group">
              <label for="admin_login" class="col-sm-2 control-label">default login</label>
              <div class="col-sm-8">
                <input type="text" class="form-control" id="admin_login" value="admin" readonly />
              </div>
            </div>
            <div class="form-group">
              <label for="admin_password" class="col-sm-2 control-label">default password</label>
              <div class="col-sm-8">
                <input type="text" class="form-control" id="admin_password" value="password" readonly />
              </div>
            </div>
          </form>
          <p>Please change the password as soon as possible.</p>
          <p>Once logged in, you can proceed to creating your email domain and accounts. Keep in mind that the server admin account is not capable of sending and receiving email, so log in with a user account and click &quot;Webmail&quot; on the top left to send and receive email.</p>
        </div>
      </div>
    </div>
  </div>

  <!-- moreinfo -->
  <div class="panel-group" id="moreinfo">
    <div class="panel panel-default">
      <div class="panel-heading">
        <h4 class="panel-title"><a data-toggle="collapse" data-parent="#moreinfo" href="#moreinfobody">Next steps</a></h4>
      </div>
      <div id="moreinfobody" class="panel-collapse collapse in">
        <div class="panel-body">
          <p>A few extra steps are necessary to make the Drobo your main email server. Those are:</p>
          <ol>
            <li>Make sure your Drobo is reachable from the internet. The following <a href="https://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers" target="_new">ports</a> must be reachable from the internet (check your <a href="http://portforward.com/" target="_new">router and/or firewall documentation</a>), and must be forwarded to the Drobo:</li>
              <ul>
                <li>Postfix: TCP:25 and TCP:465</li>
                <li>Dovecot: TCP:110, TCP:143, TCP:993, and TCP:995</li>
                <li>Modoboa: TCP:8000</li>
              </ul>
            <li>Configure the DNS <a href="https://support.google.com/a/answer/140034?hl=en" target="_new">MX records</a> on your domain to point to your public IP address.</li>
          </ol>
          <p>Once the DNS records have been updated (it may take a couple of hours), you can log in with a user account to send and receive email.</p>
        </div>
      </div>
    </div>
  </div>

  <!-- troubleshooting -->
  <div class="panel-group" id="troubleshooting">
    <div class="panel panel-default">
      <div class="panel-heading">
        <h4 class="panel-title"><a data-toggle="collapse" data-parent="#troubleshooting" href="#troubleshootingbody">Troubleshooting</a></h4>
      </div>
      <div id="troubleshootingbody" class="panel-collapse collapse">
        <div class="panel-body">
          <p><strong>Error: ['[AUTHENTICATIONFAILED] Authentication failed.']</strong></p>
          <p>Your session timed out. Please log out and log in again.</p>
          <p><strong>Error: &quot;NoReverseMatch at ... Reverse for '...' with arguments '...' and keyword arguments '...' not found.&quot;</strong></p>
          <p>Please restart mailserver. This is happening because a new extension was enabled, which requires a server restart.</p>
          <p><strong>I cannot send email.</strong></p>
          <p>Make sure that your public IP address is not <a href="<?php echo $blacklistsite; ?>" target="_new">blacklisted</a>.</p>
          <p><strong>I cannot receive email.</strong></p>
          <?php if (! $apprunning) { ?><p>Make sure that mailserver is running. Currently it seems to be <strong>stopped</strong>.</p><?php } ?>
          <p>Make sure that the MX records for your domain have been <a href="<?php echo $mxsite; ?>" target="_new">propagated</a>. You can also try a more comprehensive <a href="<?php echo $dnssite; ?>" target="_new">DNS check</a>.</p>
        </div>
      </div>
    </div>
  </div>

  <!-- logfile -->
  <div class="panel-group" id="logfile">
    <div class="panel panel-default">
      <div class="panel-heading">
        <h4 class="panel-title"><a data-toggle="collapse" data-parent="#logfile" href="#logfilebody">Log information</a></h4>
      </div>
      <div id="logfilebody" class="panel-collapse collapse">
        <div class="panel-body">
<?php foreach ($applogs as $applog) { ?>
          <p>This is the content of <code><?php echo $applog; ?></code>:</p>
          <pre class="pre-scrollable">
<?php if (substr($applog, 0, 1) === ":") {
  echo shell_exec(substr($applog, 1));
} else {
  echo file_get_contents($applog);
} ?>
          </pre>
<?php } ?>
        </div>
      </div>
    </div>
  </div>

  <!-- summary -->
  <div class="panel-group" id="summary">
    <div class="panel panel-default">
      <div class="panel-heading">
        <h4 class="panel-title"><a data-toggle="collapse" data-parent="#summary" href="#summarybody">Summary of changes</a></h4>
      </div>
      <div id="summarybody" class="panel-collapse collapse">
        <div class="panel-body">
          <p>Changes from 1.0:</p>
          <ol>
            <li>SSL certificates and modoboa sqlite database moved to <code>/mnt/DroboFS/System/mail</code>. This will prevent loss of configuration data when the app is updated or uninstalled.</li>
            <li>Modoboa updated from 1.0.0 to 1.0.1.</li>
          </ol>
        </div>
      </div>
    </div>
  </div>

    </div><!-- col -->
  </div><!-- row -->
</div><!-- container -->

<footer>
  <div class="container">
    <div class="pull-right">
      <small>All copyrighted materials and trademarks are the property of their respective owners.</small>
    </div>
  </div>
</footer>
</body>
</html>
