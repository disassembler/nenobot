#!/usr/bin/perl

my $no_lart;

BEGIN {
	$no_lart++ if ($@) ;
}

sub lart {

# This is very crude and anyone who takes this code literally, should be
# institutionalized.

	my ($target) = $_[0];
	my $extra = 0;
	
	my $linea = &getRandomLineFromFile("./conf/nenobot.lart");
	if (defined $linea) {

		$line = $linea;

		if ($target =~ /^(me|you|itself|\Q$ident\E)$/i) {
			$line =~ s/WHO/$who/g;
		} else {
			$line =~ s/WHO/$target/g;
		}

		$line .= ", courtesy of $who" if ($extra);

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
