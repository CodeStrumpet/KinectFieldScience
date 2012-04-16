import SimpleOpenNI.*;
import processing.core.*;

public class OpenNIUtils {

    
    public static PVector[] realWorldPointsFromDepthMap(int[] depthMap, int depthWidth, int depthHeight, int spacing, SimpleOpenNI context) {
	
	// create 'depthPoints' array of real world points from captured depth data
	PVector[] depthPoints = new PVector[depthWidth * depthHeight];

	for (int y = 0; y < depthHeight; y+=spacing) {
	    for (int x = 0; x < depthWidth; x+= spacing) {
		int i = y * depthWidth + x;

		int currValue = depthMap[i];
			    
		PVector realWorld = new PVector();
		PVector projective = new PVector(x, y, currValue);

		// translate from x/y to realworld coordinates
		context.convertProjectiveToRealWorld(projective, realWorld);  

		depthPoints[i] = realWorld;

	    }
	}
	
	return depthPoints;

    }

}