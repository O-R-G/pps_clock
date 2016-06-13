// Public Private Secret Clock
// O-R-G

import processing.video.*;
import java.util.Collections;
import java.util.Comparator;
import java.util.Date;
import java.text.SimpleDateFormat;
import java.io.File;
import java.io.FilenameFilter;

Movie mov;
Capture[] captures;
Capture capture;
Capture captureNext;

PixelSort pixelsort;
PixelComparator comp;
PImage[] loadedimages;

int cap;
int numpixels, ypixels, xpixels;
int pixelsize = 4;

int alpha = 100; // [0-255]
int sorttype;
int comptype;
int nullframes;
int numsorts = 6;
int numcomps = 2;
int imagescount = 60; // #/hr
int imagescounter;
int lasthour;
int lastmin;
int lastsec;

boolean playimages;
boolean playingimages;
boolean canswitchcam = false;
boolean camstarted = false;
boolean verbose = true;

void setup() {
    frameRate(30); // [30]
    noStroke();
    background(0);
	noCursor();

    try {
        println("Using usb camera . . . ");
        capture = captures[cap];
        capture.start();
    } catch (Exception e) {
        e.printStackTrace();
        printArray(Capture.list()); 
    }

	loadedimages = new PImage[imagescount];

    setResolution(pixelsize);
    pixelsort = new PixelSort(xpixels, ypixels);
}

void draw() {
    ArrayList<Pixel> pixels = new ArrayList<Pixel>();
    int h, m, s;

    h = hour();
    m = minute();
    s = second();
	/*
	if (h == 0) h = 24; // avoid 0 % 
	if (m == 0) m = 60; 
	if (s == 0) s = 60;
	*/
	lasthour = checkHour(h, lasthour);
	lastmin = checkMin(m, lastmin);
    lastsec = checkSec(s, lastsec);

    // use `date mmddHHMMyy.ss` for dev
	if (verbose)
		println(nf(h,2) + ":" + nf(m,2) + ":" + nf(s,2));	

	// scale(0.5);

	if (playimages) 
		if (imagesLoaded(imagescount))
			playImages(imagescount, loadedimages, 1);

	if (!playingimages)
    	pixels = getPixels(capture);

    if (pixels != null && !playingimages) {
        pixels = pixelsort.sort(pixels, comptype, sorttype);

        for (int j = 0; j < ypixels; j++) {
            for (int i = 0; i < xpixels; i++) {
                int index = (j * xpixels + i) % numpixels;
                color c = pixels.get(index).getColor();
				fill(hue(c), saturation(c), brightness(c), alpha); 
				rect(i*pixelsize, j*pixelsize, pixelsize, pixelsize);
            }
        }
        camstarted = true;
    } 
    /*
    else if (nullframes > 10 && camstarted) {
		// causing some problems
        camstarted = false;
		turnOnNextCam();
        switchCam();
    }
    */
}


// timers

int checkHour(int thish, int thislasthour) {
	if (thish != thislasthour) {
    	switch (thish) {
			case 0:
			case 12:
				// new comp
				comptype++;	
				comptype %= numcomps;
                if (verbose) println("+ " + thish);
                thislasthour = thish;
				break;
        	default:
				thislasthour = thish - 1;
				break;
		}
	}
	return thislasthour;
}

int checkMin(int thism, int thislastmin) {
	if (thism != thislastmin) {
    	switch (thism) {
			case 0:
				// nosort
				sorttype = 10; // out of range -> default:
				// playimages
			    if (imagesLoaded(imagescount))
        			playImages(imagescount, loadedimages, 1);
				// switch cam
				if (canswitchcam)
					switchCam();
				if (verbose) println("+ " + thism);
				thislastmin = thism;
            	break;
			case 5: 
				// new sort
				sorttype++;
		 		sorttype %= numsorts;
				if (verbose) println("+ " + thism);
				thislastmin = thism;
				break;
			case 14: 
			case 29: 
			case 44:
				// next cam
				turnOnNextCam();
	            if (verbose) println("** turnOnNextCam() ** " + captures.length);
				if (verbose) println("+ " + thism);
				thislastmin = thism;
				break;
			case 15: 
			case 30: 
			case 45:
				// switch cam
				if (canswitchcam)
					switchCam();
	            if (verbose) println("** switchCam() **");
				if (verbose) println("+ " + thism);
				thislastmin = thism;
				break;
			case 59:
				// load images
				imagescount = 60;
				loadedimages = new PImage[imagescount];
				loadImages(imagescount, loadedimages);
				playimages = true;
				// next cam
				turnOnNextCam();
				if (verbose) println("+ " + thism);
				thislastmin = thism;
            	break;
        	default:
				thislastmin = thism - 1;
				break;
		}
	}
	return thislastmin;
}

int checkSec(int thiss, int thislastsec) {
	if (thiss != thislastsec) {
    	switch (thiss) {
			case 0: 
				// save image
				saveImage();
                if (verbose) println("+ " + thiss);
                thislastsec = thiss;
				break;
        	default:
				thislastsec = thiss - 1;
				break;
		}
	}
	return thislastsec;
}


// capture

ArrayList<Pixel> getPixels(Capture capture) {
    ArrayList<Pixel> pixels = new ArrayList<Pixel>();
    int x, y;
    color c;
    if (capture.available()) {
        nullframes = 0;
        capture.read();
        for (int j = 0; j < ypixels; j++) {
            y = (int) (j * pixelsize);
            for (int i = 0; i < xpixels; i++) {
                x = (int) (i * pixelsize);
                c = capture.get(x, y);
                pixels.add(new Pixel(c));
            }
        }
        return pixels;
    } else {
        nullframes++;
        return null;
    }
}

void turnOnNextCam() {
    boolean flag = true;
    while (flag) {
        flag = false;
        cap++;
        cap %= captures.length;
        captureNext = captures[cap];
        try {
            captureNext.start();
            canswitchcam = true;
        } catch (Exception e) {
            flag = true;
        }
    }
}

void switchCam() {
    capture.stop();
    capture = captureNext;
    canswitchcam = false;
}


// images

void saveImage() {
    SimpleDateFormat df;
    Date dateobj;
    String path;
    df = new SimpleDateFormat("yyyyMMdd'T'HHmmss");
    dateobj = new Date();
    path = basepath.concat(df.format(dateobj)).concat(".png");
    saveFrame(path);
    println("Saved to: ".concat(path));
}

void loadImages(int num, PImage[] stagedimages) {
	java.io.File folder = new java.io.File(dataPath(basepath));
 	String[] filenames = folder.list(pngFilter);
	filenames = reverse(filenames);

	int numfiles = min(num, filenames.length);
	println("Loading " + numfiles + " images . . .");

	for (int i = 0; i < numfiles; i++) {
		stagedimages[i] = requestImage(basepath.concat(filenames[i]));
	}

	imagescount = numfiles; // shorter if necc
	imagescounter = 0; 	// reset for display
}

void playImages(int num, PImage[] stagedimages, int loops) {
	if (imagescounter < num * loops) {               
		image(stagedimages[imagescounter % num],0,0);
		imagescounter++;
		playimages = true;
		playingimages = true;
	} else {
		playimages = false;
		playingimages = false;
	}
}

boolean imagesLoaded(int num) {
	for (int i = 0; i < num; i++) {
	    if ((loadedimages[i] == null) || (loadedimages[i].width == 0) || (loadedimages[i].width == -1)) {
			return false;
		}
	}
	return true;
}

final FilenameFilter pngFilter = new FilenameFilter() {
  	boolean accept(File dir, String name) {
    	return name.toLowerCase().endsWith(".png");
  	}
};


// utility

void setResolution(int thispixelsize) {
    pixelsize = thispixelsize;
    if (pixelsize == 0)
        pixelsize = 1; 
    xpixels = width / pixelsize;
    ypixels = height / pixelsize;
    numpixels = xpixels * ypixels;
    pixelsort = new PixelSort(xpixels, ypixels);
    println(xpixels);
    println(ypixels);
}

void keyPressed() {
    switch(key) {
        case ' ':
			if (sorttype != 10) 
				sorttype = 10;
			else 
 				sorttype = 0;
            break;
        case 'd':
            saveImage();
            break;
        case 's':
	        sorttype++;
    	    sorttype %= numsorts;
            break;
        case 'c':
            comptype++;
    	    comptype %= numcomps;
            break;
        case 'n':
			turnOnNextCam();
			if (verbose) println("** turnOnNextCam() ** " + captures.length);
            break;
        case 'm':
			if (captures.length > 1 && canswitchcam)
				switchCam();
			if (verbose) println("** switchCam() **");
            break;
        case '+':
            setResolution(pixelsize+1);
            println("pixelsize : " + pixelsize);
            break;
        case '_':
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
        case 'i':
			imagescount = 60;
			loadedimages = new PImage[imagescount];
	    	loadImages(imagescount, loadedimages);
			playimages = true;
            break;
        case 'o':
			imagescount = 60;
			loadedimages = new PImage[imagescount];
			playimages = false;
            break;
        default:
            break;
    }
}
