import processing.core.*;
import unlekker.util.*;
import unlekker.modelbuilder.*;
import SimpleOpenNI.*;


public class ModelFactory {
    
    PApplet parent = null;
    UGeometry model;
    UVertexList vertexList;
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

	// setup model and vertexList for mesh
	model = new UGeometry();
	vertexList = new UVertexList();
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

    public void updateModel() {
	
	parent.pushMatrix();
	//translate(-sensorImageWidth, -sensorImageHeight/2, 2000);
	parent.rotateX(parent.radians(180));

	model.beginShape(PApplet.TRIANGLES);
   
	int faceCount = 0;
	for (int y = 0; y < depthHeight -spacing; y+=spacing) {
	    for (int x = 0; x < depthWidth -spacing; x+= spacing) {
		int i = y * depthWidth + x;
	    
		int nw = i;
		int ne = nw + spacing;
		int sw = i + depthWidth * spacing;
		int se = sw + spacing;

		if (!allZero(depthPoints[nw]) && !allZero(depthPoints[ne]) && !allZero(depthPoints[sw]) && !allZero(depthPoints[se])) {
		    model.addFace(new UVec3(depthPoints[nw].x, depthPoints[nw].y, depthPoints[nw].z),
				  new UVec3(depthPoints[ne].x, depthPoints[ne].y, depthPoints[ne].z),
				  new UVec3(depthPoints[sw].x, depthPoints[sw].y, depthPoints[sw].z));

		    model.addFace(new UVec3(depthPoints[ne].x, depthPoints[ne].y, depthPoints[ne].z),
				  new UVec3(depthPoints[se].x, depthPoints[se].y, depthPoints[se].z),
				  new UVec3(depthPoints[sw].x, depthPoints[sw].y, depthPoints[sw].z));

		    faceCount += 2;
		}	                
	    }
	}

	parent.popMatrix();
    }

    public void drawDepth() {

	parent.fill(255);
	parent.pushMatrix();
	//translate(-sensorImageWidth, -sensorImageHeight/2, 2000);
	parent.rotateX(parent.radians(180));
	
	for (int y = 0; y < 480 -spacing; y+=spacing) {
	    for (int x = 0; x < 640 -spacing; x+= spacing) {
		int i = y * 640 + x;

		parent.stroke(255);
		PVector currentPoint = depthPoints[i];
		if (currentPoint.z < depthMaxDist) {
		    parent.point(currentPoint.x, currentPoint.y, currentPoint.z);
		}
	    }
	}
	parent.popMatrix();
    }

    public void exportMesh(String filePath) {

	model.calcBounds();
	model.translate(0, 0, -depthMaxDist);

	float modelWidth = (model.bb.max.x - model.bb.min.x);
	float modelHeight = (model.bb.max.y - model.bb.min.y);

	UGeometry backing = Primitive.box(modelWidth/2, modelHeight/2, 10);
	model.add(backing);
    
	model.scale(0.01f);
	model.rotateY(parent.radians(180));
	model.toOrigin();
    
	model.endShape();
	model.writeSTL(parent, filePath);
	//	model.writeSTL(this, OUTPUT_DIRECTORY + "//scan_"+random(1000)+".stl");
	//println("FaceCount:  " + faceCount + "  FaceNum:  " + model.faceNum); //"   Cleaned up Points:  " + cleanedUpPoints);
    }
    

    boolean allZero(PVector p) {
	return (p.x == 0 && p.y == 0 && p.z == 0);
    }    
    
}