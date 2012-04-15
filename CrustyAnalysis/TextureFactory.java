import processing.core.*;

public class TextureFactory {

    PApplet parent = null;

    public TextureFactory(PApplet parent) {
	this.parent = parent;
    }

    PImage depthMapToTexture(int[] depthMap, float depthMaxDist) {

	PApplet.println("Number of elements in depthMap:  " + depthMap.length);		    
	int minValue = 0;
	int maxValue = 0; 
					
	for (int i = 0; i < depthMap.length; i++) {
	    int currValue = depthMap[i];
			
	    // set the minValue at the lowest non-zero value 
	    if (minValue == 0 && currValue > 0) {
		minValue = currValue;
	    }
						
	    if (i == 0) {
		maxValue = currValue;
	    } else {
							
		if (currValue < minValue && currValue > 0) {
		    minValue = currValue;
		}
		if (currValue > maxValue) {
		    maxValue = currValue;
		}
	    }
	}
					
	PApplet.println("DepthMap minValue: " + minValue + "  maxValue: " + maxValue);
					
	int scaleFactor = 255 / (maxValue - minValue);
					
	// create image for texture
	PImage depthTextureImage = parent.createImage(640, 480, PApplet.RGB);
	depthTextureImage.loadPixels();
					
	// set pixel color values for texture
	for (int i = 0; i < 640 * 480; i++) {
						
	    int currValue = depthMap[i];
						
	    // make sure the currValue is within our distance threshold, and if not then set it to 0
	    if (currValue > depthMaxDist) {
		currValue = 0;
	    }
						
	    /* to create our color value we do the following:
	     *
	     * subtract min value (this makes the minimum value now 0)
	     * multiply by scale factor (the scale factor is the number of times the max value goes into 255) (this now makes the max value 255)
	     * we would prefer light values to be closer so we flip the scale by subtracting 255 and taking the absolute value (0 goes to 255, 255 goes to 0)  
	     */					
	    int colorValue = 255;
	    if (currValue > 0) {
		colorValue = ((currValue - minValue) * scaleFactor);
		//colorValue = Math.abs(((currValue - minValue) * scaleFactor) - 255); // use this one if you want closer values to be lighter	
	    }						
						
	    depthTextureImage.pixels[i] = parent.color(colorValue, colorValue, colorValue);
	}

	return depthTextureImage;
    }
}