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
int lasth;
int lastm;
int lasts;

boolean canswitchcam;
boolean playimages;
boolean playingimages;
boolean sort;
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

    sort = true;
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
    
   	lasth = checkHour(h, lasth);
	// lastm = checkMin(m, lastm);
	lasts = checkMin(s, lasts);
    // lasts = checkSec(s, lasts);

    // use `date mmddHHMMyy.ss` for dev
    if (verbose)
 		println(nf(h,2) + ":" + nf(m,2) + ":" + nf(s,2));	

	if (playimages) 
		if (imagesLoaded(imagescount))
			playImages(imagescount, loadedimages, 1);

	if (!playingimages) 
    	pixels = getPixels(capture);

    if (nullframes > 30)
        pixels = makePixels();

    if (pixels != null && !playingimages) {
        if (sort)
            pixels = pixelsort.sort(pixels, comptype, sorttype);

        for (int j = 0; j < ypixels; j++) {
            for (int i = 0; i < xpixels; i++) {
                int index = (j * xpixels + i) % numpixels;
                color c = pixels.get(index).getColor();
				fill(hue(c), saturation(c), brightness(c), alpha); 
				rect(i*pixelsize, j*pixelsize, pixelsize, pixelsize);
            }
        }
    }
}


// timers

int checkHour(int thish, int thislasth) {
	if (thish != thislasth) {
    	switch (thish) {
			case 0:
			case 12:
				// new comp
				comptype++;	
				comptype %= numcomps;
                if (verbose) println("+ " + thish);
                thislasth = thish;
				break;
        	default:
				break;
		}
	}
	return thislasth;
}

int checkMin(int thism, int thislastm) {
	if (thism != thislastm) {
    	switch (thism) {
	   		case 0:
	    		// switch cam
 				switchCam();
		   		// dont sort
                sort = false;
		    	// playimages
                if (imagesLoaded(imagescount))
        			playImages(imagescount, loadedimages, 1);
                playimages=true;
				if (verbose) println("+ " + thism);
				thislastm = thism;
            	break;
			case 5: 
    		    // new sort
                sort = true;
				sorttype++;
		 		sorttype %= numsorts;
				if (verbose) println("+ " + thism);
				thislastm = thism;
 				break;
			case 14: 
			case 29: 
			case 44:
				// next cam
				turnOnNextCam();
				if (verbose) println("+ " + thism);
				thislastm = thism;
				break;
			case 15: 
			case 30: 
			case 45:
				// switch cam
				switchCam();
				if (verbose) println("+ " + thism);
				thislastm = thism;
				break;
			case 59:
				// next cam
				turnOnNextCam();
				// load images
				imagescount = 60;
				loadedimages = new PImage[imagescount];
				loadImages(imagescount, loadedimages);
				if (verbose) println("+ " + thism);
				thislastm = thism;
            	break;
            default:
				break;
		}
	}
	return thislastm;
}

int checkSec(int thiss, int thislasts) {
	if (thiss != thislasts) {
    	switch (thiss) {
			case 0: 
				// save image
				saveImage();
                if (verbose) println("+ " + thiss);
                thislasts = thiss;
				break;
        	default:
				break;
		}
	}
	return thislasts;
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

ArrayList<Pixel> makePixels() {
    ArrayList<Pixel> pixels = new ArrayList<Pixel>();
    int x, y;
    color c;
        
    for (int j = 0; j < ypixels; j++) {
        y = (int) (j * pixelsize);
        for (int i = 0; i < xpixels; i++) {
            x = (int) (i * pixelsize);
            c = color(int(random(50)), int(random(50)), int(random(50)));
            pixels.add(new Pixel(c));
        }
    }
    return pixels;
}

void turnOnNextCam() {
    if (!canswitchcam && captures.length > 1) {
        boolean flag = true;
        while (flag) {
            flag = false;
            cap++;
            cap %= captures.length;
            captureNext = captures[cap];
            try {
                captureNext.start();
            } catch (Exception e) {
                if (verbose) println("exception " + e);
                flag = true;
            }
        }
        if (verbose) println("++ turnOnNextCam() --> " + cap);
        canswitchcam = true;
    }
}

void switchCam() {
    if (canswitchcam) {
        capture.stop();
        capture = captureNext;
        if (verbose) println("++ switchCam() --> " + capture);
        canswitchcam = false;
    }
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
	if (verbose)
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
    println(xpixels + " x " + ypixels);
}

void keyPressed() {
    switch(key) {
        case ' ':
            sort = !sort;
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
            break;
        case 'm':
			switchCam();
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
