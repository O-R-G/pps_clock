// Public Private Secret Clock
// O-R-G
// requires https://github.com/singintime/ipcapture

// ** todo ** shuffle partial arrays to make patterns
// ** todo ** sort using bit shifting to get specific color values
// ** todo ** implement byte reader
// ** todo ** examine asdf pixelsort
// ** todo ** exchange random image rows?

import processing.video.*;
import ipcapture.*;

Movie mov;
Capture cam;
IPCapture ipcam;

color colors[];

boolean ip = false;		// ip cam 
boolean usb = true;		// usb cam
int pixels, pixelsH, pixelsW;
int pixelSize = 8;
int sortProgress;
int alpha = 255;	// [0-255]
float sortSpeed = 5.0;
float scale = 1.0;
String ipsrc = "http://192.168.1.21/live";	
String movsrc = "basement-k.mov";

void setup() {
  	size(640, 360);
	frameRate(60);
  	noStroke();
	if (ip) {
	  	println("Using ip camera . . . ");
		ipcam = new IPCapture(this, ipsrc, "", "");
		ipcam.start();
	} else if (usb) {
	  	println("Using usb camera . . . ");
		// println("Available cameras . . . ");
		// printArray(Capture.list());
	    cam = new Capture(this, 640, 360, "FaceTime HD Camera (Display)",30);
    	cam.start();     
	} else {
  		println("Using local mov . . . ");
		mov = new Movie(this, movsrc);
	  	mov.loop();
	} 
  	pixelsW = width / pixelSize;
  	pixelsH = height / pixelSize;
  	pixels = pixelsW * pixelsH;
  	colors = new color[pixels];
  	println("Pixels : " + pixels);
}

void draw() {

	// background(0);
	sortProgress+=sortSpeed;

	if (ip && ipcam.isAvailable()) ipcam.read();
	if (usb && cam.available()) cam.read();
	if (!ip && !usb && mov.available()) mov.read();
	int count = 0;
	for (int j = 0; j < pixelsH; j++) {
		for (int i = 0; i < pixelsW; i++) {
			if (ip)  colors[count] = ipcam.get(i*pixelSize, j*pixelSize);
			if (usb) colors[count] = cam.get(i*pixelSize, j*pixelSize);	
			if (!ip && !usb) colors[count] = mov.get(i*pixelSize, j*pixelSize);	
			count++;
		}
	}

	// sort

	// colors = sort(colors,sortProgress%(pixels-1));
	// colors = sort(colors);
	shuffleArray(colors);

	// display

	for (int j = 0; j < pixelsH; j++) {
    	for (int i = 0; i < pixelsW; i++) {
			// fill(colors[j*pixelsW + i]);
			fill(colors[j*pixelsW + i], alpha);
			rect(i*pixelSize*scale, j*pixelSize*scale, pixelSize*scale, pixelSize*scale);
			// rect(i*pixelSize*scale, j*pixelSize*scale, pixelSize/4, pixelSize/4);
		}
  	}

	// ** todo ** write out to video
	// saveFrame("out/frame-####.png");

	// * debug *

	// printArray(colors);
	// println("colors[0] " + hex(colors[0]) );
	println("colors[0] " + binary(colors[0]) );
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
