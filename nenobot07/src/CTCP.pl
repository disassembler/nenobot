# infobot (c) 1997 Lenzo

sub parsectcp {
    my ($nick, $user, $host, $type, $dest) = @_;
    &status("CTCP: $type request from $nick (".$user."@".$host.") to $dest.");
    if ($type =~ /^version/i) {
	ctcpreply($nick, "VERSION", $version);
    }
}

sub ctcpReplyParse {
    my ($nick, $user, $host, $type, $reply) = @_;
    &status("CTCP $type reply from $nick: $reply");
}


sub ctcpreply {
    my ($rnick, $type, $reply) = @_;
    rawout("NOTICE $rnick :\001$type $reply\001");
}

1;
