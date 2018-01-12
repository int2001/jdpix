#!/usr/bin/perl -w

use strict;
use Time::HiRes qw(usleep);
use Data::Dumper;
use jdpix;

# Initalise LEDs
my $maxx=16;
my $maxy=16;
my $client=new jdpix({host => "trixel", port => 7777, leds =>256, maxx => $maxx, maxy => $maxy});

my $bright=64;

while (1) {
	draw_circles(6);
	#wave_topdown();
	#wave_diagonal();
}

$client->init_arr();
$client->show();

$client->disconnect();

sub draw_circles {
	my ($rad)=@_;
	for (my $i=-$rad;$i<($client->{'maxx'}+$rad);$i++) {
		my $yprozent=($i+$rad)/($client->{'maxx'}+($rad*2));
		my $ypos=int(sin(($yprozent*(3.14152*4)))*($client->{'maxy'}/2));
		$client->aacircle($i,$ypos+($client->{'maxy'}/2),$rad,$client->CHSV(0,255,64));
		$client->aacircle($ypos+($client->{'maxy'}/2),$i,$rad,$client->CHSV(80,255,64));
		$client->show();
		$client->init_arr();
		usleep(1000*100);
	}
}

sub wave_diagonal {
	for (my $i=0;$i<32;$i++) {
		$client->drawline(0,$i,$i,0,$client->CHSV($i*4,255,64)) if ($i<16);
		$client->drawline($i%16,15,15,$i%16,$client->CHSV($i*4,255,64)) if ($i>15);
		usleep(1000*20);
		$client->show();
		$client->fade2black(int($bright/$client->{'maxx'}));
	}
}

sub wave_topdown {
	for (my $y=0;$y<$maxy;$y++) {
		for (my $x=0;$x<$maxx;$x++) {
			my $led=$client->xy2led($x,$y);
			$client->set_hsv($led,(($y)*(255/$maxx))%255,255,$bright);
		}
		$client->show();
		$client->fade2black(int($bright/($maxx/2)));
		usleep(1000*20);
	}
}

sub onceall {
	for (my $y=0;$y<$maxy;$y++) {
		for (my $x=0;$x<$maxx;$x++) {
			my $led=$client->xy2led($x,$y);
			$client->fade2black(int($bright/$maxx));
			$client->set_hsv($led,($x*$y)%255,255,$bright);
			$client->show();
			usleep(1000*25);
		}
	}
}

