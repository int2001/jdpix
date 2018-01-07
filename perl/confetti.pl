#!/usr/bin/perl -w

use strict;
use Time::HiRes qw(usleep);
use jdpix;

# Initalise LEDs
my $client=new jdpix({host => "trixel", port => 7777, leds =>256});

# Do Confetti 8192 Times
for (my $looper=0;$looper<8192;$looper++) {
	$client->confetti(($looper++%256));
	usleep(1000*30);
}

$client->disconnect();
