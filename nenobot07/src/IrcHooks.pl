# ChangeLog
# 0.7p8 IrcActionHook modified.
#       Now loggable actions =)
#	IrcMsgHook now recognizes control characters.
#	Removed some CPU whoring regular expressions.
# 0.7p7 Slight adjustments.
sub IrcActionHook {
    my ($who, $channel, $message) = @_;

    &channel($channel);
    &process($who, 'public action', $message);

    if ($msgType =~ /public/) {
	&status("* $who/$channel $origMessage"); # fixed by the nenolod =)
    } else {
	&status("* $who $origMessage");
    }
}

sub IrcMsgHook {
    my ($type, $channel, $who, $message) = @_;

    $origMessage = $message; # preserve it.

    if ($type =~ /public/i)	{
	&channel($channel);

	# let the sanity checks begin.

	# check for the address character, and if it is there, strip it.
	if ($message =~ /^\Q$param{'controlcharacter'}\E/i) {
		# We have the thingar. Remove it. --nenolod
		$addressed = 1;
		#$message =~ s/\Q$param{'controlcharacter'}\E//g; 
		($trash, $message) = split($param{'controlcharacter'}, $message, 2);
		&process($who, $type, $message); # that way it doesnt just talk
	};

	if ($message =~ /^\Q$param{'nick'}\E/i) { # nick addressing
		$addressed = 1;
		&process($who, $type, $message);
	};

	# the process call -should- not have been here.
	&status("<$who/$channel> $origMessage");
    }

    if ($type =~ /private/i) {
	if (($params{'mode'} eq 'IRC') && ($who eq $prevwho)) {
	    $delay = time() - $prevtime;
	    $prevcount++;

	    if (0 and $delay < 1) {
		# this is where to put people on ignore if they flood you
		if (IsFlag("o") ne "o") {
		    &msg($who, "You will be ignored -- flood detected.");
		    &postInc(ignore => $who);
		    &log_line("ignoring ".$who);
		    return;
		}
	    }
	    return if (($message eq $prevmsg) && ($delay < 10));
	    $prevcount = 0;
	    $firsttime = time;
	}

	$prevtime = time unless ($message eq $prevmsg);
	$prevmsg = $message;
	$prevwho = $who;
	&process($who, $type, $message);
	&status("[$who] $origMessage");
    }
    return;

}

sub hook_dcc_request {
    my($type, $text) = @_;
    if ($type =~ /chat/i) {
	&status("received dcc chat request from $who  :  $text");
	my($locWho) = $who;
	$locWho =~ tr/A-Z/a-z/;
	$locWho =~ s/\W//;
	&docommand("dcc chat ".$who);
	&msg('='.$who, "Hello, ".$who);
    }

    return '';
}

sub hook_dcc_chat {
    my($locWho, $message)=@_;
    $msgType = "dcc_chat";
    my($saveWho) = $who;

    $who = "=".$who;
    &process($who, $msgType, $message);
    $who = $saveWho;
    return '';

}

1;
