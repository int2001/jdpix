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
		arr => $arr,			# LED-Array
		maxx => 16,			# Matrix: Maximum X-Size
		maxy => 16			# Matrix: Maximum Y-Size
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
			if ($self->{'arr'}->[$i]->[2]-$amount>=0) {
				$self->{'arr'}->[$i]->[2]-=$amount;
			} else {
				$self->{'arr'}->[$i]->[2]=0;
			}

		} else {
			if ($self->{'arr'}->[$i]->[0]-$amount>=0) {
				$self->{'arr'}->[$i]->[0]-=$amount;
			} else {
				$self->{'arr'}->[$i]->[0]=0;
			}
			if ($self->{'arr'}->[$i]->[1]-$amount>=0) {
				$self->{'arr'}->[$i]->[1]-=$amount;
			} else {
				$self->{'arr'}->[$i]->[1]=0;
			}
			if ($self->{'arr'}->[$i]->[2]-$amount>=0) {
				$self->{'arr'}->[$i]->[2]-=$amount;
			} else {
				$self->{'arr'}->[$i]->[2]=0;
			}
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

sub CHSV {
	my ($self,$h,$s,$v)=@_;
	return($h,$s,$v,1);
}

sub CRGB {
	my ($self,$r,$g,$b)=@_;
	return($r,$g,$b,0);
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
	my($self,$x,$y)=@_;
	my ($i,$reverseY);
	$i=-1;
	if (($x<$self->{'maxx'}) && ($x>=0) && ($y<$self->{'maxy'}) && ($y>=0)) {
		my $upperpanel=0;
		$y=16-1-$y;
		if ( $x > 7 ) { # 2 Panelreihe? Dann 8 abziehen.
			$x=$x-8;
			$upperpanel=0; 
		} else {
			$upperpanel=1;
		}
		if(($y%2)==1) { # Ungerade Reihen werden Rückwärts gezählt.
			$reverseY = (8 - 1) - $x;
			$i = ($y * 8) + $reverseY;
		} else {
			$i = ($y * 8) + $x;
		}
		if (($upperpanel)) { # Obere Panelreihe? Dann 128 draufaddieren
			$i=$i+128;
		}
	}
	return $i;
}

sub drawline {
	my($self,$x1,$y1,$x2,$y2,$r,$g,$b,$mode)=@_;
	my $dx=$x2-$x1;
	my $dy=$y2-$y1;
	if (($dx == 0) && ($dy == 0)) {
		$self->{'arr'}->[xy2led($x1,$y1)]=[$r,$g,$b,$mode];
	} elsif ($dx > 0) {
		for (my $x=$x1;($x1>$x2) ? $x>=$x2 : $x<=$x2;($x1>$x2) ? $x--: $x++) {
			$self->{'arr'}->[xy2led($x,int($y1+$dy*($x-$x1)/$dx))]=[$r,$g,$b,$mode];
		}
	} else {
		for (my $y=$y1;($y1>$y2) ? $y>=$y2 : $y<=$y2;($y1>$y2) ? $y--: $y++) {
			$self->{'arr'}->[xy2led($y,int($x1+$dx*($y-$y1)/$dy))]=[$r,$g,$b,$mode];
		}
	}
}

sub circle {
	my ($self,$x0,$y0,$radius,$r,$g,$b,$mode)=@_;
	my $x = -$radius;
	my $y = 0;
	my $err = 2-2*$radius; # /* II. Quadrant */ 
	while ($x<0) {
		$self->{'arr'}->[$self->xy2led($x0-$x, $y0+$y)]=[$r,$g,$b,$mode]; # /*   I. Quadrant */
		$self->{'arr'}->[$self->xy2led($x0-$y, $y0-$x)]=[$r,$g,$b,$mode]; # /*   II. Quadrant */
		$self->{'arr'}->[$self->xy2led($x0+$x, $y0-$y)]=[$r,$g,$b,$mode]; # /*   III. Quadrant */
		$self->{'arr'}->[$self->xy2led($x0+$y, $y0+$x)]=[$r,$g,$b,$mode]; # /*   IV. Quadrant */
		$radius = $err;
		if ($radius <= $y) { $err += ++$y*2+1; } #          /* e_xy+e_y < 0 */
		if ($radius > $x || $err > $y) { $err += ++$x*2+1; } # /* e_xy+e_x > 0 or no 2nd y-step */
	} 
}

sub aacircle {
	my ($self,$x0,$y0,$radius,$r,$g,$b,$mode)=@_;
	my $x = $radius;
	my $y = 0;
	my ($i, $x2, $e2);
	my $err = 2-2*$radius;             
	$radius = 1-$err;
	my ($nr,$ng,$nb);
	while (1) {
		$i = ($err+2*($x+$y)-2)/$radius; 	# Correctionfactor for brightness
		$i-=1;
		if ($mode == 0) {	# RGB Correction
			$nr=int(abs($r*$i));
			$ng=int(abs($g*$i));
			$nb=int(abs($b*$i));
		} else {		# HSV Correction
			$nr=$r;
			$ng=$g;
			$nb=int(abs($b*$i));
		}
		$self->{'arr'}->[$self->xy2led($x0+$x, $y0-$y)]=[$nr,$ng,$nb,$mode]; 
		$self->{'arr'}->[$self->xy2led($x0+$y, $y0+$x)]=[$nr,$ng,$nb,$mode];
		$self->{'arr'}->[$self->xy2led($x0-$x, $y0+$y)]=[$nr,$ng,$nb,$mode];
		$self->{'arr'}->[$self->xy2led($x0-$y, $y0-$x)]=[$nr,$ng,$nb,$mode];
		last if ($x == 0);
		$e2 = $err; 
		$x2 = $x; 
		if ($err > $y) {
			$i = ($err+2*$x-1)/$radius;                              
			$i-=1;
			if ($mode == 0) {	# RGB Correction
				$nr=int(abs($r*$i));
				$ng=int(abs($g*$i));
				$nb=int(abs($b*$i));
			} else {		# HSV Correction
				$nr=$r;
				$ng=$g;
				$nb=int(abs($b*$i));
			}
			if ($i < 1) {
				$self->{'arr'}->[$self->xy2led($x0+$x, $y0-$y+1)]=[$nr,$ng,$nb,$mode]; 
				$self->{'arr'}->[$self->xy2led($x0+$y-1, $y0+$x)]=[$nr,$ng,$nb,$mode];
				$self->{'arr'}->[$self->xy2led($x0-$x, $y0+$y-1)]=[$nr,$ng,$nb,$mode];
				$self->{'arr'}->[$self->xy2led($x0-$y+1, $y0-$x)]=[$nr,$ng,$nb,$mode];
			}  
			$err -= --$x*2-1; 
		} 
		if ($e2 <= $x2--) {   
			$i = (1-2*$y-$e2)/$radius;  
			$i-=1;
			if ($mode == 0) {	# RGB Correction
				$nr=int(abs($r*$i));
				$ng=int(abs($g*$i));
				$nb=int(abs($b*$i));
			} else {		# HSV Correction
				$nr=$r;
				$ng=$g;
				$nb=int(abs($b*$i));
			}
			if ($i < 1) {
				$self->{'arr'}->[$self->xy2led($x0+$x2, $y0-$y)]=[$nr,$ng,$nb,$mode]; 
				$self->{'arr'}->[$self->xy2led($x0+$y, $y0+$x2)]=[$nr,$ng,$nb,$mode];
				$self->{'arr'}->[$self->xy2led($x0-$x2, $y0+$y)]=[$nr,$ng,$nb,$mode];
				$self->{'arr'}->[$self->xy2led($x0-$y, $y0-$x2)]=[$nr,$ng,$nb,$mode];
			}  
			$err -= --$y*2-1; 
		} 
	}
}

return 1;
