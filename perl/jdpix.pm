#!/usr/bin/perl -w

package jdpix;
use strict;
use IO::Socket::INET;

sub new {
	my ($class,$args)=@_;
	my $socket = new IO::Socket::INET ( PeerHost => $args->{'host'}, PeerPort => $args->{'port'}, Proto => 'udp');
	$socket->autoflush(1);
	my $arr=();
	my $self={
		host => $args->{'host'},
		port => $args->{'port'},
		leds => $args->{'leds'},
		socket => $socket,
		packetsize => 1400,
		arr => $arr
	};
	bless($self,$class);
	$self->init_arr();
	return($self);
}

sub disconnect {
	my ($self) = @_;
	if ($self->{'socket'}) {
		$self->{'socket'}->shutdown(2);
	}
}

sub confetti {
	my ($self,$looper)=@_;
	$looper++;
	my $rand_led=int(rand($self->{'leds'}));
	$self->set_hsv($rand_led,($rand_led+$looper)%255,255,64);
	$self->fade2black(1);
	$self->send_it();
}


sub fade2black {
	my($self,$amount)=@_;
	for (my $i=0;$i<=$self->{'leds'};$i++) {
		if ($self->{'arr'}->[$i]->[3]==1) {
			$self->{'arr'}->[$i]->[2]-=$amount if ($self->{'arr'}->[$i]->[2]-$amount>=0);
		} else {
			$self->{'arr'}->[$i]->[0]-=$amount if ($self->{'arr'}->[$i]->[0]-$amount>=0);
			$self->{'arr'}->[$i]->[1]-=$amount if ($self->{'arr'}->[$i]->[1]-$amount>=0);
			$self->{'arr'}->[$i]->[2]-=$amount if ($self->{'arr'}->[$i]->[2]-$amount>=0);
		}
	}
}


sub set_rgb {
	my ($self,$led,$r,$g,$b)=@_;
	$self->{'arr'}->[$led%($self->{'leds'}+1)]->[3]=0;
	$self->{'arr'}->[$led%($self->{'leds'}+1)]->[0]=$r;
	$self->{'arr'}->[$led%($self->{'leds'}+1)]->[1]=$g;
	$self->{'arr'}->[$led%($self->{'leds'}+1)]->[2]=$b;
}

sub set_hsv {
	my ($self,$led,$r,$g,$b)=@_;
	$self->{'arr'}->[$led%($self->{'leds'}+1)]->[3]=1;
	$self->{'arr'}->[$led%($self->{'leds'}+1)]->[0]=$r;
	$self->{'arr'}->[$led%($self->{'leds'}+1)]->[1]=$g;
	$self->{'arr'}->[$led%($self->{'leds'}+1)]->[2]=$b;
}

sub init_arr {
	my ($self)=@_;
	for (my $i=0;$i<=$self->{'leds'};$i++) {
		$self->{'arr'}->[$i]->[3]=0;
		$self->{'arr'}->[$i]->[0]=0;
		$self->{'arr'}->[$i]->[1]=0;
		$self->{'arr'}->[$i]->[2]=0;
	}
}

sub show {
	my ($self)=@_;
	$self->send_it();
}

sub send_it {
	my ($self)=@_;
	$self->{'frames'}++;
	my $message='';
	for (my $i=0;$i<$self->{'leds'};$i++) {
		$message.=pack("C",$i);
		$message.=pack("C",$self->{'arr'}->[$i]->[3]);
		$message.=pack("C",$self->{'arr'}->[$i]->[0]);
		$message.=pack("C",$self->{'arr'}->[$i]->[1]);
		$message.=pack("C",$self->{'arr'}->[$i]->[2]);
	}
	$message.=chr(00) while length($message)<$self->{'packetsize'};
	$self->{'socket'}->say($message);
	$self->{'socket'}->flush();
}

return 1;
