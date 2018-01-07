#!/usr/bin/perl -w

use strict;
use Time::HiRes qw(usleep);
use jdpix;

# Initalise LEDs
my $client=new jdpix({host => "trixel", port => 7777, leds =>256});

# Blank All LEDs
for (my $led=0;$led<$client->{'leds'};$led++) {
	$client->set_rgb($led,0,0,0);
	$client->show();
}

$client->disconnect();
