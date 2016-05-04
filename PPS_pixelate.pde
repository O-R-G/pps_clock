// Public Private Secret Clock
// O-R-G
// requires https://github.com/singintime/ipcapture

// ** todo ** sort using bit shifting to get specific color values
// ** todo ** implement byte reader
// ** todo ** examine asdf pixelsort
// ** todo ** exchange random image rows?
// ** todo ** add keydown control
// ** fix ** float scale
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
boolean kunthshuffle = false;	// shuffle pixels
int pixels, ypixels, xpixels;
int pixelsize = 8;
int sortprogress;
int alpha = 50;					// [0-255]
float sortspeed = 5.0;
float scale = 1.0;	// ** fix **
String ipsrc = "http://192.168.1.21/live";	
String usbsrc = "FaceTime HD Camera (Display)";	
String movsrc = "basement.mov";

void setup() {
  	size(640, 360);
	frameRate(60);
	colorMode(HSB, 255);
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

  	xpixels = width / pixelsize;
  	ypixels = height / pixelsize;
  	pixels = xpixels * ypixels;
  	colors = new color[pixels];
  	println("Pixels : " + pixels);

	// init pixelmap[]

	pixelmap = new int[pixels];

	for (int i = 0; i < pixelmap.length; i++) {
		pixelmap[i] = i;
	}
	printArray(pixelmap);
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

	// sort

	if (display) {
		pixelmap = sort(pixelmap);
		display = !display;
	}

	if (sort) {
		// colors = sort(colors,sortprogress%(pixels-1));
		// colors = sort(colors);
		// pixelmap = sort(pixelmap);
		sort = !sort;
	}

	if (kunthshuffle) {
		shuffleArray(pixelmap);
		kunthshuffle = !kunthshuffle;
	}

	// display

	for (int j = 0; j < ypixels; j++) {
    	for (int i = 0; i < xpixels; i++) {

			fill(hue(colors[pixelmap[j*xpixels + i]]), saturation(colors[pixelmap[j*xpixels + i]]), brightness(colors[pixelmap[j*xpixels + i]]), alpha);
			// fill(hue(colors[pixelmap[j*xpixels + i]]), saturation(colors[pixelmap[j*xpixels + i]])*3, brightness(colors[pixelmap[j*xpixels + i]]), alpha);
			// fill(hue(colors[pixelmap[j*xpixels + i]]), 255, 255, alpha);
			// fill(hue(colors[pixelmap[j*xpixels + i]]), 255, brightness(colors[pixelmap[j*xpixels + i]]), alpha);

			rect(i*pixelsize*scale, j*pixelsize*scale, pixelsize*scale, pixelsize*scale);
		}
  	}

	// ** todo ** write out to video
	// saveFrame("out/frame-####.png");

	// * debug *

	// printArray(pixelmap);
	// printArray(colors);
	// println("colors[0] " + hex(colors[0]) );
	// println("colors[0]   " + binary(colors[0]) );
	// println("pixelmap[0] " + binary(pixelmap[0]) );
}

void shuffleArray(int[] array) {
 
	// *note* -- when an array is passed to a function,
	// it is passed as a memory location not as data 
	// so actions transform the original variable directly
	// to act on the array's data and return a new array,
	// then the function must be typed, array data copied,
	// and a new array returned at the end.

	// knuth shuffle
	// https://en.wikipedia.org/wiki/Fisher–Yates_shuffle

	// ** todo ** add parameter to shuffle only part of an array

  	for (int i = array.length; i > 1; i--) {
 
		int j = int(random(i));
     	int tmp = array[j];
		array[j] = array[i-1];
		array[i-1] = tmp;
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
			kunthshuffle = !kunthshuffle;		
    		break;
		default:
    		break;
	}
}

