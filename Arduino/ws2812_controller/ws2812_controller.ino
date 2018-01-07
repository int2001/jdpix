#include <Arduino.h>
#include <ESP8266WiFi.h>
#include <WiFiUdp.h>
#include "ws2812_i2s.h"
#include "config.h"

// Set to the number of LEDs in your LED strip
#define NUM_LEDS 256
// Maximum number of packets to hold in the buffer. Don't change this.
#define BUFFER_LEN 1400
// Connect D-IN of your WS2812B Strip to "RX" on your ESP. Pin is NOT Changeable, because the ws2812-lib uses some kind of DMA/I2S-Magic, which can only be used on that pin!

// Wifi and socket settings - Create file "config.h" with following content:
/*
const char* ssid     = "Your SSID";
const char* password = "Your Password";
const char* dhchname = "trixel";
*/

unsigned int localPort = 7777;
char packetBuffer[BUFFER_LEN];
// LED strip
static WS2812 ledstrip;
static Pixel_t pixels[NUM_LEDS];
WiFiUDP port;


void setup() {
    Serial.begin(115200);
    WiFi.hostname(dhchname);
    WiFi.begin(ssid, password);
    WiFi.hostname(dhchname);
    Serial.println("");
    // Connect to wifi and print the IP address over serial
    while (WiFi.status() != WL_CONNECTED) {
        delay(500);
        Serial.print(".");
    }
    Serial.println("");
    Serial.print("Connected to ");
    Serial.println(ssid);
    Serial.print("IP address: ");
    Serial.println(WiFi.localIP());
    port.begin(localPort);
    ledstrip.init(NUM_LEDS);
}

uint8_t N = 0;

void setHsv (uint8_t n, uint8_t h, uint8_t s, uint8_t v) {
  uint8_t r, g, b, hi;
  float ss,vv,f,p,q,t,hh;
  hh=(float)(((float)h/255)*360.0);
   ss=(float)(s)/255;
   vv=(float)(v)/255;
   hi=(int)(hh)/60;
   f=( (float(hh)/60)-float(hi) );
   p=vv*(1.0-ss);
   q=vv*(1.0-(ss*f));
   t=vv*(1.0-(ss*(1-f)));

  if ((hi == 0) || (hi == 6)) {
    pixels[n].R=(uint8_t)(vv*255);
    pixels[n].G=(uint8_t)(t*255);
    pixels[n].B=(uint8_t)(p*255);
  } else if (hi == 1) {
    pixels[n].R=(uint8_t)(q*255);
    pixels[n].G=(uint8_t)(vv*255);
    pixels[n].B=(uint8_t)(p*255);
  } else if (hi == 2) {
    pixels[n].R=(uint8_t)(p*255);
    pixels[n].G=(uint8_t)(vv*255);
    pixels[n].B=(uint8_t)(t*255);
  } else if (hi == 3) {
    pixels[n].R=(uint8_t)(p*255);
    pixels[n].G=(uint8_t)(q*255);
    pixels[n].B=(uint8_t)(vv*255);
  } else if (hi == 4) {
    pixels[n].R=(uint8_t)(t*255);
    pixels[n].G=(uint8_t)(p*255);
    pixels[n].B=(uint8_t)(vv*255);
  } else if (hi == 5) {
    pixels[n].R=(uint8_t)(vv*255);
    pixels[n].G=(uint8_t)(p*255);
    pixels[n].B=(uint8_t)(q*255);
  }
}


void udphandler() {
      // Read data over socket
    int packetSize = port.parsePacket();
    // If packets have been received, interpret the command
    if (packetSize) {
        int len = port.read(packetBuffer, BUFFER_LEN);
        for(int i = 0; i < len; i+=5) {
            packetBuffer[len] = 0;
            N = packetBuffer[i];
            if (packetBuffer[i+1] == 0) {
              pixels[N].R = (uint8_t)packetBuffer[i+2];
              pixels[N].G = (uint8_t)packetBuffer[i+3];
              pixels[N].B = (uint8_t)packetBuffer[i+4];
            } else {
              setHsv(N,(uint8_t)packetBuffer[i+2],(uint8_t)packetBuffer[i+3],(uint8_t)packetBuffer[i+4]);
            }
        } 
        ledstrip.show(pixels);
    }
}

void loop() {
  udphandler();
}

