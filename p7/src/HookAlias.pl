#!/usr/bin/perl

sub action {

my ($target, $txt) = @_;
    if (!defined $txt) {
	&WARN("action: txt == NULL.");
	return;
    }

    my $rawout = "PRIVMSG $target :\001ACTION $txt\001";
    if (length $rawout > 510) {
	&status("action: txt too long; truncating.");

	chop($rawout) while (length($rawout) > 510);
	$rawout .= "\001";
    }

    &status("* $ident/$target $txt");
    rawout($rawout);

}

1;
