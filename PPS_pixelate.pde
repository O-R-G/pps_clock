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
import java.util.Collections;
import java.util.Comparator;

Movie mov;
Capture cam;
IPCapture ipcam;


boolean ip = false;                 // ip cam 
boolean usb = true;                 // usb cam

boolean hsb = false;                // enforce HSB color model
boolean sort = false;               // sort pixels
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

float scale = 1.0;                  // scale video input
float sortspeed = 100.0;

String ipsrc = "http://192.168.1.21/live";
String usbsrc = Capture.list()[0];
String movsrc = "basement.mov";

PixelComparator comp;

// dynamically set the size because I CAN.
public void settings()
{
    int w, h;
    
    if (usb)
    {   
        String[] arr = usbsrc.split(",");
        String[] wh = arr[1].split("=")[1].split("x");
        
        w = Integer.parseInt(wh[0]);
        h = Integer.parseInt(wh[1]);
    }
    else
    {
        w = 640;
        h = 360; 
    }

    size(w, h);
}

void setup()
{
    frameRate(60);
    noStroke();
    background(0);
    
    // start the cameras
    if (ip)
    {
        println("Using ip camera . . . ");
        ipcam = new IPCapture(this, ipsrc, "", "");
        ipcam.start();
    } 
    else if (usb)
    {
        println("Using usb camera . . . ");
        // printArray(Capture.list());
        cam = new Capture(this, usbsrc);
        cam.start();
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
    int x, y, count;
    color c;
    
    count = 0;
    pixels = new ArrayList<Pixel>();
    
    if (ip && ipcam.isAvailable())
        ipcam.read();
    if (usb && cam.available())
        cam.read();
    if (!ip && !usb && mov.available())
        mov.read();
    
    for (int j = 0; j < ypixels; j++)
    {
        y = j * pixelsize;
        for (int i = 0; i < xpixels; i++)
        {
            x = i * pixelsize;
            
            if (ip) 
                c = ipcam.get(x, y);
            else if (usb)
                c = cam.get(x, y);
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
    // color c;
    for (int j = 0; j < ypixels; j++) {
        for (int i = 0; i < xpixels; i++) {
            // fill(hue(colors[pixelmap[j*xpixels + i]]), saturation(colors[pixelmap[j*xpixels + i]]), brightness(colors[pixelmap[j*xpixels + i]]), alpha);
            // fill(red(colors[pixelmap[j*xpixels + i]]), green(colors[g[j*xpixels + i]]), blue(colors[pixelmap[j*xpixels + i]]), alpha);

            int index = (j * xpixels + i + shiftarrayamt) % numpixels;
            
            // fill(red(colors[pixelmap[index]]), green(colors[pixelmap[index]]), blue(colors[pixelmap[index]]), alpha);
            c = pixels.get(index).getColor();
            fill(red(c), green(c), blue(c), alpha);
            
            colorMode(HSB, 255);
            fill(hue(c), 255, 255, alpha);
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

