<p><strong>Error: ['[AUTHENTICATIONFAILED] Authentication failed.']</strong></p>
<p>Your session timed out. Please log out and log in again.</p>
<p><strong>Error: &quot;NoReverseMatch at ... Reverse for '...' with arguments '...' and keyword arguments '...' not found.&quot;</strong></p>
<p>Please restart mailserver. This is happening because a new extension was enabled, which requires a server restart.</p>
<p><strong>I cannot send email.</strong></p>
<p>Make sure that your public IP address is not <a href="<?php echo $blacklistsite; ?>" target="_new">blacklisted</a>.</p>
<p><strong>I cannot receive email.</strong></p>
<?php if (! $apprunning) { ?><p>Make sure that mailserver is running. Currently it seems to be <strong>stopped</strong>.</p><?php } ?>
<?php if ($publicip == "") { ?><p>Make sure that your internet connection is working. Currently it seems your Drobo cannot retrieve its public IP address.</p><?php } ?>
<p>Make sure that your ports are correctly forwarded and <a href="<?php echo $portscansite; ?>" target="_new">reachable from the internet</a>. If not, please contact your ISP to unblock them.</p>
<p>Make sure that the MX records for your domain have been <a href="<?php echo $mxsite; ?>" target="_new">propagated</a>. You can also try a more comprehensive <a href="<?php echo $dnssite; ?>" target="_new">DNS check</a>.</p>