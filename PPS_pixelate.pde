// Public Private Secret Clock
// O-R-G
// requires https://github.com/singintime/ipcapture

// ** todo ** fix sortColumns()
// ** todo ** fix sortRows()
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

color colors[];						// raw pixel color vals
int pixelmap[];						// pixel display mapping

boolean ip = false;					// ip cam 
boolean usb = true;					// usb cam
boolean hsb = false;				// enforce HSB color model
boolean sort = false;				// sort pixels
boolean sortrows;					// sort rows, alternating
boolean sortcolumns;				// sort columns (messed up)
boolean shiftarray;					// linear shift, ring buffer
boolean knuthshuffle;				// shuffle pixels
int pixels, ypixels, xpixels;
int pixelsize = 4;
int sortprogress;
int alpha = 50;						// [0-255]
int shiftarrayamt;
float scale = 1.0;					// scale video input
float sortspeed = 100.0;
String ipsrc = "http://192.168.1.21/live";	
// String usbsrc = "HD USB Camera";	
// String usbsrc = "FaceTime HD Camera (Display)";	
String usbsrc = "FaceTime Camera (Built-in)";	
String movsrc = "basement.mov";

void setup() {
	size(640, 360);
	// size(1280, 720);
	frameRate(60);
	// if (hsb) colorMode(HSB, 255);
  	noStroke();
	background(0);

	if (ip) {
	  	println("Using ip camera . . . ");
		ipcam = new IPCapture(this, ipsrc, "", "");
		ipcam.start();
	} else if (usb) {
	  	println("Using usb camera . . . ");
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

	// adjust colors, pixelmap

	if (sortprogress < pixels-1) sortprogress+=sortspeed;

	if (sort) {
		colors = sort(colors);
		// colors = reverse(sort(colors, sortprogress));
		// colors = sort(colors, sortprogress);
	}

	if (sortrows) {
		sortRows(colors, ypixels);
	}

	if (sortcolumns) {
		sortColumns(colors, xpixels);
	}

	if (shiftarray) {
		shiftarrayamt+=10;
		// shiftarrayamt = shiftArray(pixelmap, shiftarrayamt, 10,);
	}

	if (knuthshuffle) {

		knuthShuffle(pixelmap, 0, pixels);
		// knuthShuffle(pixelmap, 0, sortprogress);
		// knuthShuffle(pixelmap, int(random(pixels-1)), int(random(pixels)));
	} 

	if (!knuthshuffle) pixelmap = sort(pixelmap);

	// display

	for (int j = 0; j < ypixels; j++) {
    	for (int i = 0; i < xpixels; i++) {
			// fill(hue(colors[pixelmap[j*xpixels + i]]), saturation(colors[pixelmap[j*xpixels + i]]), brightness(colors[pixelmap[j*xpixels + i]]), alpha);
			// fill(red(colors[pixelmap[j*xpixels + i]]), green(colors[pixelmap[j*xpixels + i]]), blue(colors[pixelmap[j*xpixels + i]]), alpha);

			int index = (j * xpixels + i + shiftarrayamt) % pixels;

			fill(red(colors[pixelmap[index]]), green(colors[pixelmap[index]]), blue(colors[pixelmap[index]]), alpha);

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

	// acting directly on array, so no need to return any value

  	for (int i = max; i > min; i--) {
		int j = int(random(min,max));
     	int tmp = array[j];
		array[j] = array[i-1];
		array[i-1] = tmp;
	}
}

public int shiftArray(int[] array, int amt, int offset) {
	// either:	
	// 1. assign global shift amt, which is incremented and % when read
	// 2. arrayCopy to modify pixelmap

	// splice last amt items into beginning of the array
	// shorten the array by amt
	// acting directly on array, so no need to return any value

	offset+=amt;

/*
	for (int i = 0; i < pixels/8; i++) {
		int tmp = array[i]; // get discrete value
		println(tmp);
		array = splice(array, tmp, 0);
		println(array);
		// ** fix ** can also splice in arrays in total
		// see https://processing.org/reference/splice_.html
		// array = splice(array, array[10], 0);
		array = shorten(array);
		println(array.length);
		exit();
	}
*/

	shiftarray = true;
	return offset;
}

void sortArray(int[] array, int min, int max) {
	// todo
}

void sortRows(int[] array, int rows) {

	int[] imgBuffer = new int[1];
	int[] rowBuffer = new int[xpixels];
	boolean odd = true;

    for (int j = 0; j < ypixels; j++) {
        for (int i = 0; i < xpixels; i++) {
			rowBuffer[i] = colors[j*xpixels + i];
		}
		rowBuffer = sort(rowBuffer);
		if (odd) rowBuffer = reverse(rowBuffer);
		imgBuffer = concat(imgBuffer,rowBuffer);
		odd = !odd;
	}
	imgBuffer = shorten(imgBuffer);
	arrayCopy(imgBuffer, array);	// works directly on data
}

void sortColumns(int[] array, int columns) {

	// not correct, but perhaps interesting

	int[] imgBuffer = new int[1];
	int[] colBuffer = new int[ypixels];
	boolean odd = true;

    for (int j = 0; j < xpixels; j++) {
        for (int i = 0; i < ypixels; i++) {
			colBuffer[i] = colors[j*ypixels + i];
		}
		colBuffer = sort(colBuffer);
		if (odd) colBuffer = reverse(colBuffer);
		imgBuffer = concat(imgBuffer,colBuffer);
		odd = !odd;
	}
	imgBuffer = shorten(imgBuffer);
	arrayCopy(imgBuffer, array);
}





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
		case ' ':
			hsb = !hsb;
			if (hsb) colorMode(HSB, 255);
			if (!hsb) colorMode(RGB, 255);
    		break;
		case 's':
			sort = !sort;
			sortprogress = 0;
    		break;
		case 'r':
			sortrows = !sortrows;
			sortprogress = 0;
    		break;
		case 'c':
			sortcolumns = !sortcolumns;
			sortprogress = 0;
    		break;
		case 'k':  
			knuthshuffle = !knuthshuffle;
			sortprogress = 0;
    		break;
		case 'h':
			shiftarray = !shiftarray;
			sortprogress = 0;
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

