#!/usr/bin/perl -w

use strict;
use Time::HiRes qw(usleep);
use jdpix;

# Initalise LEDs
my $client=new jdpix({host => "trixel", port => 7777, leds =>256});

my $maxx=16;
my $maxy=16;

# Blank All LEDs
for (my $y=0;$y<$maxy;$y++) {
	for (my $x=0;$x<$maxx;$x++) {
		my $led=xy2led($x,$y);
		$client->fade2black(int(64/16));
		$client->set_hsv($led,($x*$y)%255,255,64);
		$client->show();
		usleep(1000*20);
	}
}

$client->init_arr();
$client->show();

$client->disconnect();

sub xy2led {
	# Rechnet X,Y in LED-pos an.
	# Funktioniert bei folgendem Setup:
	# 4 8x8 Panel wie folgt zusammengeschaltet:
	# --> 1 -> 2
	#  -> 3 -> 4
	# Laufrichtung innerhalb eines Panels:
	#  1, 2, 3, 4, 5, 6, 7, 8
	# 16,15,14,13,12,11,19, 9 
	# 17,18,19,20,21,22,23,24 usw.
	#
	my($x,$y)=@_;
	my $upperpanel=0;
	my ($i,$reverseY);
	$x=16-1-$x;
	if ( $y > 7 ) { # 2 Panelreihe? Dann 8 abziehen.
		$y=$y-8;
		$upperpanel=0; 
	} else {
		$upperpanel=1;
	}
	if(($x%2)==1) { # Ungerade Reihen werden Rückwärts gezählt.
		$reverseY = (8 - 1) - $y;
		$i = ($x * 8) + $reverseY;
	} else {
		$i = ($x * 8) + $y;
	}
	if (($upperpanel)) { # Obere Panelreihe? Dann 128 draufaddieren
		$i=$i+128;
	}
	return $i;
}

