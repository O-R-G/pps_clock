// Public Private Secret Clock
// O-R-G

// ** todo ** write sort
// ** todo ** sort using bit shifting to get specific color values
// ** todo ** implement byte reader
// ** todo ** examine asdf pixelsort
// ** todo ** exchange random image rows?

// build array which maps pixel locations
// reset that map to show regular positions
// could be dynamically resized

import processing.video.*;
import java.util.Collections;
import java.util.Comparator;

Movie mov;
Capture[] captures = new Capture[2];
Capture capture;
Capture captureNext;
int cap = 0;
int camSwitchInterval = 5; // units = minutes
boolean canSwitchCam = false;

boolean usb;                 		// usb cam
boolean hsb;                		// enforce HSB color model
boolean sort;  	 		            // sort pixels
boolean sortrows;                   // sort rows, alternating
boolean sortrowswonky;
boolean sortcolsvhs;
boolean sortcolumns;                // sort columns (messed up)
boolean shiftarray;                 // linear shift, ring buffer
boolean knuthshuffle;               // shuffle pixels

int numpixels, ypixels, xpixels;
int pixelsize = 4;
int pixelstep = 1;
int sortprogress;
int alpha = 50;                     // [0-255]
int shiftarrayamt;
int count = 0;

float scale = 1.0;                  // scale video input
float sortspeed = 100.0;

String movsrc = "basement.mov";

PixelComparator comp;

// dynamically set the size because I CAN.
public void settings()
{
    int w, h;
    
	try 
	{
		usb = true;
		
		// add cameras to capture list
		// make sure captures array is the correct length!
		captures[0] = new Capture(this, "name=HD USB Camera,size=1296x972,fps=30");
		captures[1] = new Capture(this, "name=FaceTime HD Camera,size=1280x720,fps=30");
	} 
	catch (Exception e) 
	{
		usb = false;
		e.printStackTrace();
		w = 640;
		h = 360;
	}
	
	size(1280,720);
}

void setup()
{
    frameRate(60);
    // surface.setResizable(true);
    noStroke();
    background(0);

    // start the cameras
	if (usb)
    {
		try 
		{
		    println("Using usb camera . . . ");
            capture = captures[cap];
        	captures[cap].start();
		} 
		catch (Exception e) 
		{
			usb = false;
    		e.printStackTrace();
			printArray(Capture.list());	
  		}
    } 
    else
    {
        println("Using local mov . . . ");
        mov = new Movie(this, movsrc);
        mov.loop();
        mov.read();
        surface.setSize(mov.width, mov.height);
    }

    setResolution(pixelsize);
    comp = new BrightnessComparator();
}

void draw()
{
    ArrayList<Pixel> pixels;
    int x, y; // count;
    color c;
    
    // count = 0;
    count++;
    if (usb && canSwitchCam && (minute() % camSwitchInterval == 0))
    {  
        capture.stop();
        capture = captureNext;
        canSwitchCam = false;
    }
    pixels = new ArrayList<Pixel>();
    
    if (usb && capture.available())
        capture.read();
    if (!usb && mov.available())
        mov.read();
    
    for (int j = 0; j < ypixels; j++)
    {
        y = j * pixelsize;
        for (int i = 0; i < xpixels; i++)
        {
            x = i * pixelsize;
            
            if (usb)
                c = capture.get(x, y);
            else
                c = mov.get(x, y);

            pixels.add(new Pixel(c));
        }
    }

    // adjust pixels

    if (sortprogress < numpixels - 1) 
        sortprogress += sortspeed;

    if (sort)
    {
        Collections.sort(pixels, comp);
    }

    if (sortcolumns)
    {
        pixels = sortCols(pixels);
    }
        
    if (sortrows)
    {
        pixels = sortRows(pixels);
    }
    
    if (sortrowswonky)
    {
        pixels = sortRowsWonky(pixels);
    }
    
    if (sortcolsvhs)
    {
        pixels = sortColsVHS(pixels);
    }

    if (shiftarray)
    {
        shiftarrayamt += 1;
    }

    if (knuthshuffle)
    {   
        
        knuthShuffle(pixels, 0, sortprogress);
        // knuthShuffle(pixels, 0, numpixels);
        // knuthShuffle(pixelmap, int(random(pixels-1)), int(random(pixels)));
    } 

    // display
    for (int j = 0; j < ypixels; j++) {
        for (int i = 0; i < xpixels; i++) {
            int index = (j * xpixels + i + shiftarrayamt) % numpixels;
			c = pixels.get(index).getColor();

			// rgb 
            // fill(red(c), green(c), blue(c), alpha);

			// hsb, max s, b
            // colorMode(HSB, 255);
            // fill(hue(c), 255, 255, alpha);

			// map hsb -> rgb
            fill(hue(c), saturation(c), brightness(c), alpha);

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
    
    if (usb && (!canSwitchCam) && (minute() % camSwitchInterval == camSwitchInterval - 1) && (second() > 40))
    {  
        cap++;
        cap %= captures.length;
        captureNext = captures[cap];
        captureNext.start();
        canSwitchCam = true;
    }
}

void knuthShuffle(ArrayList<Pixel> pixels, int min, int max)
{
    for (int i = max; i > min; i--)
    {
        int j = int(random(min, max));
        Collections.swap(pixels, j, i-1);
    }
}

public int shiftArray(int[] array, int amt, int offset)
{
    // either:  
    // 1. assign global shift amt, which is incremented and % when read
    // 2. arrayCopy to modify pixelmap

    // splice last amt items into beginning of the array
    // shorten the array by amt
    // acting directly on array, so no need to return any value

    offset += amt;

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

void sortArray(int[] array, int min, int max)
{
    // todo
}

ArrayList<Pixel> sortRows(ArrayList<Pixel> plist)
{
    ArrayList<Pixel> sorted, row;
    sorted = new ArrayList<Pixel>();
    
     for (int j = 0; j < ypixels; j++)
     {
        row = new ArrayList<Pixel>();
        
        for (int i = 0; i < xpixels; i++)
            row.add(plist.get(j * xpixels + i));
            
        Collections.sort(row, comp);
        sorted.addAll(row);
     }
     
     return sorted;
}

ArrayList<Pixel> sortCols(ArrayList<Pixel> plist)
{
    ArrayList<ArrayList<Pixel>> columns;
    ArrayList<Pixel> sorted, col;
    
    sorted = new ArrayList<Pixel>();
    columns = new ArrayList<ArrayList<Pixel>>();
    
     for (int j = 0; j < xpixels; j++)
     {
        col = new ArrayList<Pixel>();
        
        for (int i = 0; i < ypixels; i++)
            col.add(plist.get(i * xpixels + j));
        
        Collections.sort(col, comp);
        
        columns.add(col);
     }
     
     for (int i = 0; i < columns.get(0).size(); i++)
     {
        for (int j = 0; j < columns.size(); j++)
        {
            sorted.add(columns.get(j).get(i));
        }
     }
     
     return sorted;
}

ArrayList<Pixel> sortRowsWonky(ArrayList<Pixel> pixels)
{
    ArrayList<Pixel> sorted, row;
    sorted = new ArrayList<Pixel>();
    
    for (int j = 0; j < ypixels; j++)
    {
        row = new ArrayList<Pixel>();
        for (int i = 0; i < xpixels; i++)
            row.add(pixels.get(j * xpixels + i));
        Collections.sort(row, comp);
        if (j % 2 == 0)
            Collections.reverse(row);
        sorted.addAll(row);
    }
    return sorted;
}

ArrayList<Pixel> sortColsVHS(ArrayList<Pixel> pixels)
{
    ArrayList<Pixel> sorted, col;
    sorted = new ArrayList<Pixel>();
    
    for (int j = 0; j < xpixels; j++)
    {
        col = new ArrayList<Pixel>();
        for (int i = 0; i < ypixels; i++)
            col.add(pixels.get(j * ypixels + i));
        
        Collections.sort(col, comp);
        if (j % 2 == 0)
            Collections.reverse(col);
        sorted.addAll(col);
    }
    return sorted;
}
void setResolution(int thispixelsize)
{
    pixelsize = thispixelsize;
    if (pixelsize == 0)
        pixelsize = 1; 
    
    xpixels = width / pixelsize;
    ypixels = height / pixelsize;
    numpixels = xpixels * ypixels;
}

void keyPressed()
{
    switch(key)
    {
        case ' ':
            hsb = !hsb;
            if (hsb)
                colorMode(HSB, 255);
            if (!hsb)
                colorMode(RGB, 255);
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
        case 'w':
            sortrowswonky = !sortrowswonky;
            sortprogress = 0;
            break;
        case 'v':
            sortcolsvhs = !sortcolsvhs;
            sortprogress = 0;
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
        default:
            break;
    }
}

public int gcd(int a, int b)
{
    if (b == 0)
        return a;
    else
        return gcd(b, a % b);
}

