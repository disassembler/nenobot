
# infobot :: Kevin Lenzo  (c) 1997
# with thanks to Patrick Cole

use Socket;

# send info to devnull
sub devnull {
    return '';
}

# ask frendly bots
sub askFriendlyBots {
    my $request = $_[0];
    return if ($request =~ /^no\,?\s+/);

    foreach $bot (split /\s+/, $param{'friendlyBots'}) {
	$request =~ s/^(is|are) //i;
	&msg($bot, ":INFOBOT:QUERY <$who> $request");
    }
}

# format a public message
sub FormatText {
    my($nick, $msg) = @_;

    undef @ret;
    undef %str;
    my $msgLen = length($msg);
    my $nickLen = length($nick);
    my $tot = 0;
    my $cnt = 0;
    foreach (split //, $msg) {
	if ($cnt == (80 - $nickLen - 3)) {
	    $tot++;
	    $cnt=0;
	}
	$str{$tot} .= $_;
	$cnt++;
    }
    foreach (keys %str) {
	push(@ret, $str{$_}."\n");
    }
    return @ret;
}

sub status {
    $statcount++;
    my($input) = @_;

    if ($param{'VERBOSITY'} > 0) {
	printf ("[%5d] $input\n", $statcount) if ($input !~ /^\s*$/);
    }

    &log_line("[$statcount] ".$input);
}

sub performSay {
    my($in) = @_;
    if (!defined($prevIn)) { $prevIn = ""; };
    if (($skipReply == 0) && ($in !~ 'NOREPLY')) {
	$prevIn = $in;
	if (0) {		# for mac speech manager niceties
	    $in =~ s/ at (ht|f)/ $1/ig;
	    $in =~ s/((ht|f)tp:\S+)/here [[cmnt $1 ]]/ig;
	}
	&say($in);
    }

    # this could echo everything to somewhere
    # &msg('somebody', ".say $in");
    return '';
}

sub performReply {
    if ($msgType eq 'private') {
	&msg($who, $_[0]);
    } else {
	&say("$_[0]");
    }
}

sub log_line {
    my($line) = @_;
    my($logwrite) = 0;

    my $s = time();

    if ($param{'logfile'} ne '') {
	$line =~ s/\n*$/\n/;

	open(TRACK, ">>$param{logfile}");

	$loglines++;
	$total_loglines++;
	print TRACK "$s $line";

	close(TRACK);		#  if (TRACK);
    }
}

sub getAllKeys {
    @myIsKeys = getDBMKeys("is");
    @myAreKeys = getDBMKeys("are"); 

    $factoidCount = $#myIsKeys + $#myAreKeys + 2;
    $updateCount = 0;
}

sub purifyNick {
    my $safeWho = $_[0];
    $safeWho =~ s/\*//g;
    $safeWho =~ s/\\/\\\\/g;
    $safeWho =~ s/\[/\\\[/g;
    $safeWho =~ s/\]/\\\]/g;
    $safeWho =~ s/\|/\\\|/g;
    $safeWho =~ tr/A-Z/a-z/;
    $safeWho = substr($safeWho, 0, 9);
    $safeWho =~ s/\s+.*//;
    return $safeWho;
}

1;

__DATA__

/dimer\[0\/: trailing \ in regexp at /usr/users/infobot/infobot-current/src/Misc.pl line 164, <FH> chunk 98.
