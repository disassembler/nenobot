#!/usr/bin/perl

my $no_lart;

BEGIN {
	$no_lart++ if ($@) ;
}

sub insult {

# This is very crude and anyone who takes this code literally, should be
# institutionalized.

	my $linea = &getRandomLineFromFile("./conf/nenobot.insult");
	if (defined $linea) {
		$line = $linea;
	} else {
		$line = "can't help you, $who.";
	}
	return $line;
}

1;

__END__

=head1 NAME

lart.pl - Luser Attitude Readjustment Tool

=head1 AUTHORS

William Pitcock <nenolod@kyrosoft.com>
