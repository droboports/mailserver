<?php
header('Cache-Control: no-store, no-cache, must-revalidate, max-age=0');
header('Cache-Control: post-check=0, pre-check=0', false);
header('Pragma: no-cache');

$appname = "Modoboa mailserver";
$appversion = "1.0.1";
$appsite = "http://modoboa.org/";
$apppage = "http://".$_SERVER['SERVER_ADDR'].":8000/";
$apphelp = "http://modoboa.org/en/support/";

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
    <div class="btn-group pull-right" role="group">
      <a class="btn btn-success" href="<?php echo $apppage; ?>" target="_new"><span class="glyphicon glyphicon-globe"></span> Go to App</a>
      <a class="btn btn-success" href="<?php echo $apphelp; ?>" target="_new"><span class="glyphicon glyphicon-question-sign"></span> Help</a>
    </div>
  </div>
</div>
<div class="container">
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
            <li>Make sure your Drobo is reachable from the internet. The following <a href="https://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers" target="_new">ports</a> must be reachable from the internet (check your <a href="http://portforward.com/" target="_new">router and/or firewall documentation</a>):</li>
              <ul>
                <li>Postfix: TCP:25 and TCP:465</li>
                <li>Dovecot: TCP:110, TCP:143, TCP:993, and TCP:995</li>
                <li>Modoboa: TCP:8000</li>
              </ul>
            <li>Configure the DNS <a href="https://support.google.com/a/answer/140034?hl=en" target="_new">MX records</a> on your domain to point to your Drobo.</li>
          </ol>
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
      <div id="summarybody" class="panel-collapse collapse in">
        <div class="panel-body">
          <p>Changes from 1.0.0:</p>
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
