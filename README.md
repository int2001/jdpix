# jdpix
## WS2812-Strip controlled by Perl via ESP8266

Small project to control a WS2812B-Matrix/Strip via Network.

Prerequisites:
* Microcontroller:
  * Arduino 1.8. IDE
  * ESP8266 Arduino Add-on - https://github.com/esp8266/Arduino
* Host
  * Perl
  * IO::Socket::INET

Change hostname (currently "trixel") to IP which is shown on Serial after WiFi-Connect in the Perl-Script, if you don't own a DHCP-Server which respects DHCP-Hostnames advertised by Clients

## Protocol:

I decided to implement a new protocol (OpenPixelControl was the template - but it didn't fit here). It's quite simple:

* UDP via Port 7777
* 5 Chars per LED
1. Number of LED (0 is start)
2. Mode (0 for RGB-Set, 1 for HSV Set)
3. R or H
4. G or S
5. B or V
* Packets must bei 1400 Bytes long (fill rest with 0x00)
