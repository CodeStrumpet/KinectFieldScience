import processing.core.*;

public class TextureFactory {

    PApplet parent = null;

    public TextureFactory(PApplet parent) {
	this.parent = parent;
    }

    PImage depthMapToTexture(int[] depthMap, float depthMaxDist) {

	IntWrapper min = new IntWrapper();
	IntWrapper max = new IntWrapper();

	ArrayUtils.getMinAndMaxFromIntArray(depthMap, min, max);
	int minValue = min.getInt();
	int maxValue = max.getInt();		
					
	int scaleFactor = 255 / (maxValue - minValue);
					
	// create image for texture
	PImage depthTextureImage = parent.createImage(640, 480, PApplet.RGB);
	depthTextureImage.loadPixels();
					
	// set pixel color values for texture
	for (int i = 0; i < depthMap.length; i++) {
						
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