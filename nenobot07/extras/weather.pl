#!/usr/bin/perl

my $no_weather;

BEGIN {
	$no_weather++ if ($@) ;
	use Geo::WeatherNWS;
}

sub weather {

	my ($station) = $_[0];

	my $weatherobj = Geo::WeatherNWS::new();

	# Now we get the report for said station. Hee!

	$weatherobj->getreporthttp($station);

	if ($weatherobj->{error}) {

	$line = "There was an error retrieving the data.";

	return $line;

	} 

	if (!$weatherobj->{winddirtext}) {

	$line = "This station does not exist.";

	return $line;

	}

	# Now... make something useful of it.

#	if ($weatherobj->{winddirtext} eq "Calm") {

#	$line = "Weather for ".$station.": Conditions - $weatherobj->{conditionstext} with no wind. Temperature is at $weatherobj->{temperature_f} deg F. Barometric Pressure is $weatherobj->{pressure_inhg} inches of mercury.";

#	} else {

#	$line = "Weather for ".$station.": Conditions - $weatherobj->{conditionstext} with winds from the $weatherobj->{winddirtext} at $weatherobj->{windspeedmph} MPH. Temperature is at $weatherobj->{temperature_f} deg F. Barometric Pressure is $weatherobj->{pressure_inhg} inches of mercury.";
	
#	}

	$line = "\002[\002Weather - $station\002]\002 Conditions: $weatherobj->{conditionstext} Winds: $weatherobj->{winddirtext} at $weatherobj->{windspeedmph} Temperature: $weatherobj->{temperature_f} Barometer: $weatherobj->{pressure_inhg}.";

	return $line;

}


1;

