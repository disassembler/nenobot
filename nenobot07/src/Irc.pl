# infobot :: Kevin Lenzo & Patrick Cole   (c) 1997
# nenobot :: William Pitcock & others     (c) 2002 - infinity

use IO::Socket;

sub srvConnect {
    my ($server, $port) = @_;
    if ($param{'vhost_name'}) {
	$link = IO::Socket::INET->new(
		PeerAddr => "$server:$port",
		Proto    => "tcp");
    } else {
	$link = IO::Socket::INET->new(
		PeerAddr  => "$server:$port",
		LocalAddr => "$param{'vhost_name'}",
		Proto     => "tcp");
    }
}

sub procservmode {
    my ($server, $e, $f) = @_;
    my @parts = split (/ /, $f);
    $cnt=0;
    my $mode="";
    my $chan="";
    foreach (@parts) {
	if ($cnt == 0) {
	    $chan = $_;
	} else {
	    $mode .= $_;
	    $mode .= " ";
	}
	++$cnt;
    }
    chop $mode;
    $mode=~s/://;

    if ($server eq $chan) {
        &status(">>> $server sets mode: $mode");
    } else {
        &status(">>> $server/$chan sets mode: $mode");
    }
}

### added by the xk.
# Usage: &nickServ(text);
sub nickServ {
    my $text	= shift;
    return if !defined $param{'nickServ_pass'};

    &status("NickServ: <= '$text'");

    if ($text =~ /Password incorrect/i) {
	&status("NickServ: ** identify failed.");
	return;
    }

    if ($text =~ /Password accepted/i) {
	&status("NickServ: ** identify success.");
	return;
    }

    if ($nickserv_try) { return; }

    &status("NickServ: => Identifying to NickServ.");
    rawout("PRIVMSG NickServ :IDENTIFY $param{'nickServ_pass'}");
    $nickserv_try++;
}

###
# Usage: &chanServ(text);
sub chanServ {
    my $text	= shift;
#    return if !defined $param{'chanServ_ops'};
    &status("chanServ_ops => '$param{'chanServ_ops'}'.");

    &status("ChanServ: <= '$text'");

    # to be continued...
    return;
}
# end of xk functions.

sub procmode {
    my ($nick, $user, $host, $e, $f) = @_;
    my @parts = split (/ /, $f);
    $cnt=0;
    my $mode="";
    my $chan="";
    foreach (@parts) {
	if ($cnt == 0) {
	    $chan = $_;
	} else {
	    $mode .= $_;
	    $mode .= " ";
	}
	++$cnt;
    }
    $mode =~ s/\s$//;


    &status(">>> mode/$chan [$mode] by $nick");

    if ($chan =~ /^[\#\&]/) {
	my ($modes, $targets) = ($mode =~ /^(\S+)\s+(.*)/);
	my @m = ($modes =~ /([+-]*\w)/g);
	my @t = split /\s+/, $targets;
	if (@m != @t) {
	    &status("number of modes does not match number of targets: @m / @t");
	} else {
	    my $parity = 0;
	    foreach (0..$#m) {
		if ($m[$_] =~ s/^([-+])//) {
		    $sign = $1;
		    if ($sign eq '-') {
			$parity = -1;
		    } else {
			$parity = 1;
		    }
		}
		if ($parity == 0) {
		    &status("zero parity mode change... ignored");
		} else {
		    if ($parity > 0) {
			$channels{$chan}{$m}{$t} = '+';
		    } else {
			delete $channels{$chan}{$mode}{$t};
		    }
		}
	    }
	}
    }
}

sub entryEvt {
    my ($nick, $user, $host, $type, $chan) = @_;
    if ($type=~/PART/) {
	&status(">>> $nick ($user\@$host) has left $chan");
    } elsif ($type=~/JOIN/) {
	if ($netsplit) {
	    foreach (keys(%snick)) {
		if ($nick eq $snick{$_}) {
		    @be = split (/ /);
		    &status(">>> Netjoined: $be[0] $be[1]");
		    $netsplit--;
		}
	    }
	}
        &status(">>> $nick ($user\@$host) has joined $chan");
    } elsif ($type=~/QUIT/) {
	$chan=~s/\r//;
	if ($chan=~/^([\d\w\_\-\/]+\.[\.\d\w\_\-\/]+)\s([\d\w\_\-\/]+\.[\.\d\w\_\-\/]+)$/) {
	    $i=0;
	    while (0 and ($i < $netsplit || !$netsplit)) {
#	    while ($i < $netsplit || !$netsplit) {
		$i++;
		if (($prevsplit1{$i} ne $2) && ($prevsplit2{$i} ne $1)) {
		    &status("Netsplit: $2 split from $1");
		    $netsplit++;
		    $prevsplit1{$netsplit} = $2;
		    $prevsplit2{$netsplit} = $1;
		    $snick{"$2 $1"}=$nick;
		    $schan{"$2 $1"}=$chan;
		}
	    }
	} else {
  	    status(">>> $nick has signed off IRC ($chan)");
	}
    } elsif ($type=~/NICK/) {
           &status(">>> $nick materializes into $chan");
    }
}

sub procevent {
    my ($nick, $user, $host, $type, $chan, $msg) = @_;

    # support global $nuh, $who
    $nuh = "$nick!$user\@$host";

    if ($type=~/PRIVMSG/) {
	if ($chan =~ /^$ischan/) {
	    ## It's a public message on the channel##
	    $chan =~ tr/A-Z/a-z/;

	    if ($msg =~ /\001(.*)\001/ && $msg !~ /ACTION/) {
		#### Client To Client Protocol ####
		parsectcp($nick, $user, $host, $1, $chan);
	    } elsif ($msg !~ /ACTION\s(.+)/) {
		#### Public Channel Message ####
 		&IrcMsgHook('public', $chan, $nick, $msg);
	    } else {
		#### Public Action ####
		&IrcActionHook($nick, $chan, $1);
	    }
	} else {
	    ## Is Private ##
	    if ($msg=~/\001(.*)\001/) {
		#### Client To Client Protocol ####
		parsectcp($nick, $user, $host, $1, $chan);
	    } else {
		#### Is a Private Message ##
		&IrcMsgHook('private', $chan, $nick, $msg);
	    }
	}
    } elsif ($type=~/NOTICE/) {
	if ($chan =~ /^$ischan/) {
	    $chan =~ tr/A-Z/a-z/;
	    if ($msg !~ /ACTION (.*)/) {
		&status("-$nick/$chan- $msg");
	    } else {
		&status("* $nick/$chan $1");
	    }
	} else {
	    if ($msg=~/\001([A-Z]*)\s(.*)\001/) {
		ctcpReplyParse($nick, $user, $host, $1, $2);
	    } else {
		&status("-$nick($user\@$host)- $msg");
	    }
	}
    }
}

sub servmsg {
    my $msg=$_[0];
    my ($ucount, $uc) = (0, 0);
    if ($msg=~/^001/) {
# joinChan(split/\s+/, $param{'join_channels'});
# Line in infobot.config:
#   join_channels #chan,key #chan_with_no_key
#
# since , is not allowed in channels, we'll use it to specify keys
# without breaking current join_channels format
	for (split /\s+/, $param{'join_channels'}) {
            # if it's a keyed chan, replace the comma with a space so it'll
	    # work as per the RFC (i.e. JOIN #chan key)
	    s/,/ /; 
	    joinChan ($_);
	}
 	$nicktries=0;
    } elsif ($msg=~/^NOTICE ($ident) :(.*)/) {
	serverNotice($1,$2);
    } elsif ($msg=~/^332 $ident ($ischan) :(.*)/) {
	&status(">>> topic for $1: $2");
    } elsif ($msg=~/^333 $ident $ischan (.*) (.*)$/) {
	# THIS IS FUN. We're GOING TO PARSE A TIMESTAMP ($2) =)
	$convtimestamp = gmtime($2);
        &status(">>> set by $1 at $convtimestamp");
    } elsif ($msg=~/^433/) {
	++$nicktries;
	if (length($param{wantNick}) > 9) {
	    $ident = chop $param{wantNick};
	    $ident .= $nicktries;
	} else {
	    $ident = $param{wantNick}.$nicktries;
	}
	if ($param{'opername'}) {
	    &rawout("OPER $param{opername} $param{operpass}");
	}
	$param{nick} = $ident;
	&status("*** Nickname $param{wantNick} in use, trying $ident");
	rawout("NICK $ident");

    } elsif ($msg=~/[0-9]+ $ident . ($ischan) :(.*)/) {
	my ($chan, $users) = ($1, $2);
	my $u;
	foreach $u (split /\s+/, $users) {
	    if (s/\@//) {
		$channels{$chan}{o}{$u}++;
	    }
	    if (s/\+//) {
		$channels{$chan}{v}{$u}++;
	    }
	}
    }
}

sub serverNotice {
    ($type, $msg) = @_;
    if ($type=~/AUTH/) {
	&status("!$param{server}! $msg");
    } else {
	$msg =~ s/\*\*\* Notice -- //;
	&status("-!$param{server}!- $msg");
    }
}

sub OperWall {
    my ($nick, $msg) = @_;
    $msg=~s/\*\*\* Notice -- //;
    &status("[wallop($nick)] $msg");
}

sub prockick {
    my ($kicker, $chan, $knick, $why) = @_;

    &status(">>> $knick was kicked off $chan by $kicker [$why]");

    if ($knick eq $ident) {
	&status(">>> Regaining: $chan");
	&joinChan($chan);
    }
}

sub prockill {
    my ($killer, $knick, $kserv, $killnick, $why) = @_;
    if ($knick eq $ident) {
	&status("KILLED by $killnick ($why)");	
    } else {
	&status("KILL $knick by $killnick ($why)");
    }
}

sub fhbits {
    local (@fhlist) = split(' ',$_[0]);
    local ($bits);
    for (@fhlist) {
	vec($bits,fileno($_),1) = 1;
    }
    $bits;
}

sub irc {
    local ($rin, $rout);
    local ($buf, $line);

    $nicktries=0;
    $connected=1;
    while ($connected) {
	srvConnect($param{server}, $param{port});

        if ($param{server_pass}) { # ksiero++
            rawout("PASS $param{server_pass}");
        }

	rawout("NICK $param{wantNick}");
	rawout("USER $param{ircuser} $param{ident} $param{server} :$param{realname}");
	if ($param{operator}) {
	    rawout("OPER $param{operName} $param{operPass}\n");
	}
	$param{nick} = $param{wantNick};
	$ident = $param{wantNick};

	while ($in = <$link>) {
		sparse($in);
	}	    
    }
}

#Corion++
# Fixed baaaad backdor in server parsing (regexes are a bitch :( )
# /msg infobot :a@b.c PRIVMSG #channel seen <nick>
# can be used to flood a channel witout getting ever caught !

# Affected lines were
# PRIVMSG / NOTICE / TOPIC / KICK

sub sparse {
    $_ = $_[0];
    s/\r//;

    if (/^PING :(\S+)/) {	# Pings are important
	rawout("PONG :$1");
	&status("SELF replied to server PING") if $param{VERBOSITY} > 2;
    } elsif (/^:\S+ ([\d]{3} .*)/) {
	servmsg($1);
    } elsif (/^:([\d\w\_\-\/]+\.[\.\d\w\_\-\/]+) NOTICE ($ident) :(.*)/) {
	&status("\-\[$1\]- $3");
    } elsif (/^NOTICE (.*) :(.*)/) {
	serverNotice($1, $2);
    } elsif (/^:NickServ!s\@NickServ NOTICE \S+ :(.*)/i) {
	&nickServ($1);		# added by the xk.
    } elsif (/^:ChanServ!s\@ChanServ NOTICE \S+ :(.*)/i) {
	&chanServ($1);		# added by the xk.
    } elsif (/^:(\S+)!(\S+)@(\S+)\s(PRIVMSG|NOTICE)\s([\#\&]?\S+)\s:(.*)/) {
	procevent($1,$2,$3,$4,$5,$6);
    } elsif (/^:(\S+)!(\S+)@(\S+)\s(PART|JOIN|NICK|QUIT)\s:?(.*)/) {
	entryEvt($1,$2,$3,$4,$5);
    } elsif (/^:(.*) WALLOPS :(.*)/) {
	OperWall($1,$2);
    } elsif (/^:(.*)!(.*)@(.*) (MODE) (.*)/) {
	procmode($1,$2,$3,$4,$5);
    } elsif (/^:(.*) (MODE) (.*)/) {
	procservmode($1,$2,$3);
    } elsif (/^:(\S+)!(?:\S+)@(?:\S+) KICK ((\#|&).+) (.*) :(.*)/) {
	prockick($1,$2,$4,$5);
    } elsif (/^ERROR :(.*)/) {
	&status("ERROR $1");
    } elsif (/^:([^! ]+)!\S+@\S+ TOPIC (\#.+) :(.*)/) {
	&status(">>> $1\[$2\] set the topic: $3");
    } elsif (/^:(\S+)!\S+@\S+ KILL (.*) :(.*)!(.*) \((.*)\)/) {
	prockill($1,$2,$3,$4,$5);
    } else {
	&status("UNKNOWN $_");
    }
#Corion--
}

	     1;
