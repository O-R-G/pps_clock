// Public Private Secret Clock
// O-R-G
// requires https://github.com/singintime/ipcapture

// ** todo ** write sort
// ** todo ** sort using bit shifting to get specific color values
// ** todo ** implement byte reader
// ** todo ** examine asdf pixelsort
// ** todo ** exchange random image rows?
// ** todo ** add keydown control
// ** fix ** pjava export always copies java

// build array which maps pixel locations
// reset that map to show regular positions
// could be dynamically resized

import processing.video.*;
import ipcapture.*;

Movie mov;
Capture cam;
IPCapture ipcam;

color colors[];					// raw pixel color vals
int pixelmap[];					// pixel display mapping

boolean ip = false;				// ip cam 
boolean usb = true;				// usb cam
boolean display = true;			// display pixels
boolean sort = false;			// sort pixels
boolean knuthshuffle = false;	// shuffle pixels
int pixels, ypixels, xpixels;
int pixelsize = 8;
int sortprogress;
int alpha = 50;					// [0-255]
float scale = 1.0;				// scale video input
float sortspeed = 5.0;
String ipsrc = "http://192.168.1.21/live";	
// String usbsrc = "FaceTime HD Camera (Display)";	
String usbsrc = "FaceTime Camera (Built-in)";	
String movsrc = "broadway-slow.mov";

void setup() {
	size(640, 360);
	// size(1280, 720);
	frameRate(60);
	// colorMode(HSB, 255);
  	noStroke();
	background(0);

	if (ip) {
	  	println("Using ip camera . . . ");
		ipcam = new IPCapture(this, ipsrc, "", "");
		ipcam.start();
	} else if (usb) {
	  	println("Using usb camera . . . ");
		// println("Available cameras . . . ");
		// printArray(Capture.list());
	    cam = new Capture(this, 640, 360, usbsrc, 30);
    	cam.start();     
	} else {
  		println("Using local mov . . . ");
		mov = new Movie(this, movsrc);
	  	mov.loop();
	} 

	setResolution(pixelsize);
}

void draw() {

	sortprogress+=sortspeed;

	if (ip && ipcam.isAvailable()) ipcam.read();
	if (usb && cam.available()) cam.read();
	if (!ip && !usb && mov.available()) mov.read();
	int count = 0;
	for (int j = 0; j < ypixels; j++) {
		for (int i = 0; i < xpixels; i++) {
			if (ip)  colors[count] = ipcam.get(i*pixelsize, j*pixelsize);
			if (usb) colors[count] = cam.get(i*pixelsize, j*pixelsize);	
			if (!ip && !usb) colors[count] = mov.get(i*pixelsize, j*pixelsize);	
			count++;
		}
	}

	// adjust pixelmap

	if (display) {
		pixelmap = sort(pixelmap);
		display = !display;
	}

	if (sort) {
		// colors = sort(colors,sortprogress%(pixels-1));
		pixelmap = sort(pixelmap);
		colors = sort(colors);
		// sort = !sort;
	}

	if (knuthshuffle) {
		knuthShuffle(pixelmap, 0, pixels);
		// knuthShuffle(pixelmap, int(random(pixels-1)), int(random(pixels)));
		// knuthshuffle = !knuthshuffle;
	}

	// display

	for (int j = 0; j < ypixels; j++) {
    	for (int i = 0; i < xpixels; i++) {

			fill(hue(colors[pixelmap[j*xpixels + i]]), saturation(colors[pixelmap[j*xpixels + i]]), brightness(colors[pixelmap[j*xpixels + i]]), alpha);
			// fill(hue(colors[pixelmap[j*xpixels + i]]), 255, 255, alpha);
			// fill(hue(colors[pixelmap[j*xpixels + i]]), 255, brightness(colors[pixelmap[j*xpixels + i]]), alpha);
			// fill(hue(colors[pixelmap[j*xpixels + i]]), 0, brightness(colors[pixelmap[j*xpixels + i]]), alpha);
			// fill(hue(colors[pixelmap[j*xpixels + i]]), brightness(colors[pixelmap[j*xpixels + i]]), 255, alpha);
			rect(i*pixelsize*scale, j*pixelsize*scale, pixelsize*scale, pixelsize*scale);
		}
  	}

	// saveFrame("out/frame-####.png");

	// printArray(pixelmap);
	// println(colors);
	// printArray(colors);
	// println("colors[0] " + hex(colors[0]) );
	// println("red(colors[0])   " + red(colors[0]) );
	// println("colors[0]   " + binary(colors[0]) );
	// println("colors[0]   " + int(binary(colors[0] >> 16 & 0xFF)));
	// println("pixelmap[0] " + binary(pixelmap[0]));
}







void knuthShuffle(int[] array, int min, int max) {

  	for (int i = max; i > min; i--) {
		int j = int(random(min,max));
     	int tmp = array[j];
		array[j] = array[i-1];
		array[i-1] = tmp;
	}
}

/*
// in process 
void shiftArray(int[] array, int min, int max) {

  	for (int i = max; i > min; i--) {
		int j = int(random(min,max));
     	int tmp = array[j];
		array[j] = array[i-1];
		array[i-1] = tmp;
	}
}
*/

void setResolution(int thispixelsize) {

	pixelsize = thispixelsize;
	if (pixelsize == 0) pixelsize = 1; 
	xpixels = width / pixelsize;
	ypixels = height / pixelsize;
	pixels = xpixels * ypixels;
	colors = new color[pixels];
	pixelmap = new int[pixels];
	for (int i = 0; i < pixelmap.length; i++) {
		pixelmap[i] = i;
	}
}

void keyPressed() {

  	switch(key) {
		case 'd':  
			display = !display;		
    		break;
		case 's':  
			sort = !sort;		
    		break;
		case 'k':  
			knuthshuffle = !knuthshuffle;		
    		break;
		case '+':  		// pixelsize++
			setResolution(pixelsize+1);
			println("pixelsize : " + pixelsize);
    		break;
		case '_': 		// pixelsize--
			setResolution(pixelsize-1);
			println("pixelsize : " + pixelsize);
    		break;
		case '=':
			if (alpha + 1 < 255) alpha++;
			println("alpha : " + alpha);
    		break;
		case '-':
			if (alpha - 1 > 0) alpha--;
			println("alpha : " + alpha);
    		break;
		default:
    		break;
	}
}

