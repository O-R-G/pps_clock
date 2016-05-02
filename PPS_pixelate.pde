// Public Private Secret Clock
// O-R-G
// requires https://github.com/singintime/ipcapture

import processing.video.*;
import ipcapture.*;

Movie mov;
IPCapture cam;

color colors[];

//boolean ip = true;
 boolean ip = false;
int pixels, pixelsH, pixelsW;
int pixelSize = 10;
int sortProgress;
float sortSpeed = 5.0;
float scale = 1.0;
String ipsrc = "http://192.168.1.21/live";	
String movsrc = "broadway-slow.mov";

void setup() {
  	size(640, 480);
	frameRate(60);
  	noStroke();
	if (ip) {
	  	println("Using ip camera . . . ");
		cam = new IPCapture(this, ipsrc, "", "");
		cam.start();
	} else if (!ip) {
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
	background(0);
	sortProgress+=sortSpeed;

	if (ip && cam.isAvailable()) cam.read();
	if (!ip && mov.available()) mov.read();
	int count = 0;
	for (int j = 0; j < pixelsH; j++) {
		for (int i = 0; i < pixelsW; i++) {
			if (ip)  colors[count] = cam.get(i*pixelSize, j*pixelSize);
			if (!ip) colors[count] = mov.get(i*pixelSize, j*pixelSize);	
			count++;
		}
	}

	colors = sort(colors,sortProgress%(pixels-1));
	// colors = sort(colors);
  
	// shuffleArray(colors);

	for (int j = 0; j < pixelsH; j++) {
    	for (int i = 0; i < pixelsW; i++) {
			fill(colors[j*pixelsW + i]);
			rect(i*pixelSize*scale, j*pixelSize*scale, pixelSize*scale, pixelSize*scale);
			// rect(i*pixelSize*scale, j*pixelSize*scale, pixelSize/4, pixelSize/4);
		}
  	}

	// ** todo ** write out to video
	// saveFrame("out/frame-####.png");
}



void shuffleArray(int[] array) {
 
	// ** not quite right, but promising **

	// https://forum.processing.org/two/discussion/3546/how-to-randomize-order-of-array
	// with code from WikiPedia; Fisher–Yates shuffle 
	//@ <a href="http://en.wikipedia.org/wiki/Fisher" target="_blank" rel="nofollow">http://en.wikipedia.org/wiki/Fisher</a>–Yates_shuffle
   
  	// i is the number of items remaining to be shuffled.
  	for (int i = array.length; i > 1; i--) {
 
    	// Pick a random element to swap with the i-th element.    	
		int j = int(random(i));
 
    	// Swap array elements.
    	int tmp = array[j];
		array[j] = array[i-1];
		array[i-1] = tmp;
	}
}
