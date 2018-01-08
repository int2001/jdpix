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
		host => $args->{'host'},	# Host or IP of the ESP
		port => $args->{'port'},	# Port of the ESP
		leds => $args->{'leds'},	# Count of LEDs (should match to NUM_LEDS in Sketch)
		socket => $socket,		# Holds the Socket
		packetsize => 1400,		# Packetsize (must match to packetsize in Sketch)
		arr => $arr			# LED-Array
	};
	bless($self,$class);
	$self->init_arr();			# initialise the Array once
	return($self);
}

sub disconnect {
	my ($self) = @_;
	if ($self->{'socket'}) {
		$self->{'socket'}->shutdown(2);
	}
}

sub confetti {					# Demo
	my ($self,$looper)=@_;
	$looper++;
	my $rand_led=int(rand($self->{'leds'}));
	$self->set_hsv($rand_led,($rand_led+$looper)%255,255,64);
	$self->fade2black(1);
	$self->send_it();
}


sub fade2black {				# Fades all LEDs down by $amount (works for HSV and RGB)
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


sub set_rgb {					# Set RGB-LED $led to $g $g and $b
	my ($self,$led,$r,$g,$b)=@_;
	$self->{'arr'}->[$led%($self->{'leds'}+1)]->[3]=0;
	$self->{'arr'}->[$led%($self->{'leds'}+1)]->[0]=$r;
	$self->{'arr'}->[$led%($self->{'leds'}+1)]->[1]=$g;
	$self->{'arr'}->[$led%($self->{'leds'}+1)]->[2]=$b;
}

sub set_hsv {					# Set HSV $led to $h $s $v
	my ($self,$led,$h,$s,$v)=@_;
	$self->{'arr'}->[$led%($self->{'leds'}+1)]->[3]=1;
	$self->{'arr'}->[$led%($self->{'leds'}+1)]->[0]=$h;
	$self->{'arr'}->[$led%($self->{'leds'}+1)]->[1]=$s;
	$self->{'arr'}->[$led%($self->{'leds'}+1)]->[2]=$v;
}

sub init_arr {					# Initialise the whole Array with black
	my ($self)=@_;
	for (my $i=0;$i<=$self->{'leds'};$i++) {
		$self->{'arr'}->[$i]->[3]=0;
		$self->{'arr'}->[$i]->[0]=0;
		$self->{'arr'}->[$i]->[1]=0;
		$self->{'arr'}->[$i]->[2]=0;
	}
}

sub show {					# Alias for send_it
	my ($self)=@_;
	$self->send_it();
}

sub send_it {					# Transmits Array to ESP
	my ($self)=@_;
	$self->{'frames'}++;
	my $message='';
	for (my $i=0;$i<$self->{'leds'};$i++) {
		$message.=pack("C",$i);					# 1st Byte: # of LED
		$message.=pack("C",$self->{'arr'}->[$i]->[3]);		# 2nd Byte: RGB (0) or HSV (1)
		$message.=pack("C",$self->{'arr'}->[$i]->[0]);		# 3rd Byte: Red (when RGB) or Hue (when HSV)
		$message.=pack("C",$self->{'arr'}->[$i]->[1]);		# 4th Byte: Green (when RGB) or Saturation (when HSV)
		$message.=pack("C",$self->{'arr'}->[$i]->[2]);		# 5th Byte: Blue (when RGB) or Value (when HSV)
	}
	$message.=chr(00) while length($message)<$self->{'packetsize'};	# Fill Packet to packetsize
	$self->{'socket'}->say($message);				# Send via UDP
	$self->{'socket'}->flush();					# Flush it (no delay!)
}

return 1;
