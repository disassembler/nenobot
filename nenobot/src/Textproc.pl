#!/usr/bin/perl
#
# nenobot: text processing.
#

# getRandomLineFromFile: Was written at about 4 AM. Probably buggy as hell.
sub getRandomLineFromFile {
	my($file) = @_;

	if (!open(IN, $file)) {
		my $err = "I couldn't open the file, $file!";
		return $err;
	}

	my @lines = <IN>;
	close IN;

	if (!scalar @lines) {
		my $err = "Nothing's here!!!";
		return $err;
	}
	
	while (my $line = &getRandom(@lines)) {
		chop $line;

		next if ($line =~ /^\#/);
		next if ($line =~ /^\s*$/);

		return $line;
	}
}

sub getRandom {
	my @array = @_;

	srand();
	return $array[int(rand(scalar @array))];
}

1;
