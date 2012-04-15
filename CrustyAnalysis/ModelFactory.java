import processing.core.*;
import unlekker.util.*;
import unlekker.modelbuilder.*;
import SimpleOpenNI.*;


public class ModelFactory {

    PApplet parent = null;
    PVector[] depthPoints;
    SimpleOpenNI context;
    int spacing = 0;
    float depthMaxDist = 0;
    int pointDisregardThreshold = 10;
    int depthWidth;
    int depthHeight;

    public ModelFactory(PApplet parent, PVector[] depthPoints, SimpleOpenNI context, int depthWidth, int depthHeight, int spacing, float depthMaxDist) {
	this.parent = parent;
	this.depthPoints = depthPoints;
	this.context = context;
	this.depthWidth = depthWidth;
	this.depthHeight = depthHeight;
	this.spacing = spacing;
	this.depthMaxDist = depthMaxDist;
    }

    
    public void cleanUp() {
	int cleanedUpPoints = 0;

	// cleanup pass
	for (int y = 0; y < depthHeight; y+=spacing) {
	    for (int x = 0; x < depthWidth; x+= spacing) {
		int i = y * depthWidth + x;
		PVector p = depthPoints[i];

	   

		// if the point is on the edge or if it has no depth
		if (p.z < pointDisregardThreshold || p.z > depthMaxDist || y == 0 || y == depthHeight - spacing || x == 0 || x == depthWidth - spacing) {

		    // replace it with a point at the depth of the backplane (i.e. depthMaxDist)
		    PVector realWorld = new PVector();
		    PVector projective = new PVector(x, y, depthMaxDist);

		    // to get the point in the right place, we need to translate
		    // from x/y to realworld coordinates to match our other points:
		    context.convertProjectiveToRealWorld(projective, realWorld);  // do we have to recreate this every time??

		    depthPoints[i] = realWorld;

		    cleanedUpPoints++;
		}
	    }
	}
    }
    
}