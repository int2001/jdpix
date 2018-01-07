#!/usr/bin/perl -w

use strict;
use Data::Dumper;
use IO::Socket::INET;
use Time::HiRes qw(usleep);

# initialize host and port
my $host = 'trixel';
my $port = 7777;

$|=1;

my ($socket);
$socket = new IO::Socket::INET ( PeerHost => $host, PeerPort => $port, Proto => 'udp');
$socket->autoflush(1);


my $frames=0;
my $led_cnt=255;
my $arr;
init_arr(\$arr,$led_cnt);
my $durchlauf=0;

while (1) {
	$durchlauf++;
	set_hsv(\$arr,int(rand($led_cnt)),$durchlauf%255,255,64);
	#set_rgb(\$arr,int(rand($led_cnt)),int(rand(128)),int(rand(128)),int(rand(128)));
	fade2black(\$arr,$led_cnt,2);
	send_it(\$arr);
	usleep(1000*20);
}


print $frames."\n";
close($socket);

sub fade2black {
	my($ref_arr,$leds,$amount)=@_;
	for (my $i=0;$i<=$leds;$i++) {
		if ($$ref_arr->[$i]->[3]==1) {
			$$ref_arr->[$i]->[2]-=$amount if ($$ref_arr->[$i]->[2]-$amount>=0);
		} else {
			$$ref_arr->[$i]->[0]-=$amount if ($$ref_arr->[$i]->[0]-$amount>=0);
			$$ref_arr->[$i]->[1]-=$amount if ($$ref_arr->[$i]->[1]-$amount>=0);
			$$ref_arr->[$i]->[2]-=$amount if ($$ref_arr->[$i]->[2]-$amount>=0);
		}
	}
}


sub set_rgb {
	my ($ref_array,$led,$r,$g,$b)=@_;
	$$ref_array->[$led%($led_cnt+1)]->[3]=0;
	$$ref_array->[$led%($led_cnt+1)]->[0]=$r;
	$$ref_array->[$led%($led_cnt+1)]->[1]=$g;
	$$ref_array->[$led%($led_cnt+1)]->[2]=$b;
}

sub set_hsv {
	my ($ref_array,$led,$r,$g,$b)=@_;
	$$ref_array->[$led%($led_cnt+1)]->[3]=1;
	$$ref_array->[$led%($led_cnt+1)]->[0]=$r;
	$$ref_array->[$led%($led_cnt+1)]->[1]=$g;
	$$ref_array->[$led%($led_cnt+1)]->[2]=$b;
}

sub init_arr {
	my ($ref_arr,$leds)=@_;
	for (my $i=0;$i<=$leds;$i++) {
		$$ref_arr->[$i]->[3]=0;
		$$ref_arr->[$i]->[0]=0;
		$$ref_arr->[$i]->[1]=0;
		$$ref_arr->[$i]->[2]=0;
	}
}

sub send_it {
	my ($ref_arr)=@_;
	$frames++;
	my $message='';
	for (my $i=0;$i<scalar(@$$ref_arr);$i++) {
		$message.=pack("C",$i);
		$message.=pack("C",$$ref_arr->[$i]->[3]);
		$message.=pack("C",$$ref_arr->[$i]->[0]);
		$message.=pack("C",$$ref_arr->[$i]->[1]);
		$message.=pack("C",$$ref_arr->[$i]->[2]);
	}
	$message.=chr(00) while length($message)<1400;
	$socket->say($message);
	$socket->flush();
}

