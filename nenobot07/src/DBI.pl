#!/usr/bin/perl
#
# DBI.pl -- Database Interface
#
# Gets the parameter from the nenobot.config file.
#

my $database_backend = "DBM";

require("./src/DBIs/". $database_backend .".pl");