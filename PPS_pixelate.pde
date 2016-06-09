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

int cap = 0;
int camswitchinterval = 15; // units = minutes
boolean canswitchcam = false;

int saveimageinterval = 1;
int saveimagelastmin = -1;

int sortswitchinterval = 10;
int sortswitchlastmin = -1;

int compswitchinterval = 5;
int compswitchlastmin = -1;

int imagesplayinterval = 3;
int imagesplaylastmin = -1;

int numpixels, ypixels, xpixels;

int outpixelsize = 6;
int inpixelsize = 4;
int pixelsize = 6;
int pixelstep = 1;

int alpha = 100; // [0-255]
int count = 0;

int sorttype = 1;
int comptype = 0;

int numsorts = 7;
int numcomps = 3;

boolean camstarted = false;
int nullframes = 0;

PixelSort pixelsort;
PixelComparator comp;

PImage[] loadedimages;
boolean playimages;

int imagescount;
int imagescounter;

void setup()
{
    frameRate(30);
    noStroke();
    background(0);
	noCursor();

    // start the cameras
    try 
    {
        println("Using usb camera . . . ");
        capture = captures[cap];
        capture.start();
    } 
    catch (Exception e) 
    {
        e.printStackTrace();
        printArray(Capture.list()); 
    }

	imagescount = int(60/saveimageinterval);
	loadedimages = new PImage[imagescount];

    setResolution(pixelsize);
    pixelsort = new PixelSort(xpixels, ypixels);
}

ArrayList<Pixel> getPixels(Capture capture)
{
    ArrayList<Pixel> pixels = new ArrayList<Pixel>();
    int x, y;
    color c;
    
    if (capture.available())
    {
        nullframes = 0;
        capture.read();
    
        for (int j = 0; j < ypixels; j++)
        {
            y = (int) (j * inpixelsize);
            for (int i = 0; i < xpixels; i++)
            {
                x = (int) (i * inpixelsize);
                c = capture.get(x, y);
                pixels.add(new Pixel(c));
            }
        }
        return pixels;
    }
    else
    {
        nullframes++;
        return null;
    }
}

void draw()
{
    ArrayList<Pixel> pixels = new ArrayList<Pixel>();
    int m, s;
    
    m = minute();
    s = second();
    count++;
	// println(nf(m,2) + ":" + nf(s,2));	// display timer

    // switch cameras
    if (captures.length > 1 && m % camswitchinterval == 0 && canswitchcam)
    {
        switchCams();
    }
    
    // start the next camera 20 seconds early
    if (!canswitchcam && (m % camswitchinterval == camswitchinterval - 1) && (s > 40))
    {
        turnOnNextCam();
    }
    
	if (!playimages)
    	pixels = getPixels(capture);

    // switch sort every compswitchinterval minutes
    // choose random sort
    if (m % sortswitchinterval == 0 && sortswitchlastmin != m)
    {
        // choose random sort
        sorttype = int(random(0, numsorts));
        sortswitchlastmin = m;
    }

    // switch comps every compswitchinterval minutes        
    if (m % compswitchinterval == 0 && compswitchlastmin != m)
    {
        // choose random pixelcomp
        comptype = int(random(0, numcomps));
        compswitchlastmin = m;
    }

	// load images every imagesplayinterval-1 minutes
    if (m % imagesplayinterval == imagesplayinterval-1 && imagesplaylastmin != m)
    {
		loadedimages = new PImage[imagescount];
		loadImages(imagescount, loadedimages);
        imagesplaylastmin = m;
    }
	
    // play images every imagesplayinterval minutes        
    if (m % imagesplayinterval == 0 || playimages)
    {
		if (imagesLoaded(imagescount)) 
		{
			// draw images in sequence
			image(loadedimages[imagescounter % imagescount],0,0);	
			playimages = true;
			imagescounter++;
		} 
    } else 
	{
		playimages = false;
	}

    if (pixels != null && !playimages)
    {
        // sort!
        pixels = pixelsort.sort(pixels, comptype, sorttype);

        // display
        for (int j = 0; j < ypixels; j++) {
            for (int i = 0; i < xpixels; i++) {
                int index = (j * xpixels + i) % numpixels;
                color c = pixels.get(index).getColor();
				
				// map hsb -> rgb
                fill(hue(c), saturation(c), brightness(c), alpha); 
                
				rect(i*pixelsize, j*pixelsize, pixelsize, pixelsize);
            }
        }
    
        // save a frame every saveimageinterval minutes
        if ((m % saveimageinterval == 0) && (m != saveimagelastmin) && s == 30)
        {
            saveImage();
            saveimagelastmin = m;		
        }

        camstarted = true;
    }
    else if (nullframes > 10 && camstarted)
    {
		turnOnNextCam();
        switchCams();
        camstarted = false;
    }
}

void turnOnNextCam()
{
    boolean flag = true;
    while (flag)
    {
        flag = false;
        cap++;
        cap %= captures.length;
        captureNext = captures[cap];
        // make sure next camera is available
        try {
            captureNext.start();
            canswitchcam = true;
        }
        // move on to the next-next
        catch (Exception e) {
            flag = true;
        }
    }
}

void switchCams()
{
    capture.stop();
    capture = captureNext;
    canswitchcam = false;
}

void saveImage()
{
    SimpleDateFormat df;
    Date dateobj;
    String path;
    
    df = new SimpleDateFormat("yyyyMMdd'T'HHmmss");
    dateobj = new Date();
    
    path = basepath.concat(df.format(dateobj)).concat(".png");
    saveFrame(path);
    println("Saved to: ".concat(path));
}

void loadImages(int num, PImage[] stagedimages)
{
	// loadedimages[] passed as pointer (no need to return)
	// https://forum.processing.org/one/topic/listing-last-10-modified-files-in-directory

	java.io.File folder = new java.io.File(dataPath(basepath));
 	String[] filenames = folder.list(pngFilter);
	filenames = reverse(filenames);		// last modified
	for (int i = 0; i < num; i++) 
	{
		println("Loading images . . .");
		stagedimages[i] = requestImage(basepath.concat(filenames[i]));
	}
}

boolean imagesLoaded(int num)
{
	for (int i = 0; i < num; i++) 
	{
	    if ((loadedimages[i] == null) || (loadedimages[i].width == 0) || (loadedimages[i].width == -1))
			return false;
	}	
	return true;
}

final FilenameFilter pngFilter = new FilenameFilter() 
{
  	boolean accept(File dir, String name) 
	{
    	return name.toLowerCase().endsWith(".png");
  	}
};

void setResolution(int thispixelsize)
{
    pixelsize = thispixelsize;
    if (pixelsize == 0)
        pixelsize = 1; 
    
    xpixels = width / pixelsize;
    ypixels = height / pixelsize;
    numpixels = xpixels * ypixels;
    println(xpixels);
    println(ypixels);
}

void keyPressed()
{
    switch(key)
    {
        case 'd':
            saveImage();
            break;
        case 's':
            sorttype++;
            break;
        case 'c':
            comptype++;
            break;
        case '+':       // pixelsize++
            setResolution(pixelsize+1);
            println("pixelsize : " + pixelsize);
            break;
        case '_':       // pixelsize--
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
			loadedimages = new PImage[imagescount];
	    	loadImages(imagescount, loadedimages);
			playimages = true;
            break;
        case 'o':
			loadedimages = new PImage[imagescount];
			playimages = false;
            break;
        default:
            break;
    }
}
