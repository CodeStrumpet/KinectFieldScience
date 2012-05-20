import SimpleOpenNI.*;
import com.sun.image.codec.jpeg.*;
import hypermedia.video.*;
import java.awt.image.BufferedImage;
import org.json.*;
import unlekker.util.*;
import unlekker.modelbuilder.*;
import processing.opengl.*;
import javax.imageio.*;


SimpleOpenNI  context; 
OpenCV opencv;

int spacing = 3; // determines level of resolution for exported mesh

PFont f;
int windowWidth = 0; 
int windowHeight = 0;
int imageRegionPadding = 10;
int textRegionHeight = 300;
String debugLog = "";

final String OUTPUT_DIRECTORY = "data/output/PostZZYZX";  //"data\\output\\PostZZYZX";
final String INPUT_DIRECTORY = "data/output";  //"data\\output";

final String SITE_ID_KEY = "siteID";
final String USE_SENSOR_CAPTURE_STREAM = "useSensorCaptureStream  ('/')";
final String UPDATE_SOURCE_IMAGE = "updateSourceImage  (']')";
final String DEPTH_MAX_DIST_KEY = "depthMaxDist  ('<' , '>')";
final String DEPTH_THRESHOLD_KEY = "depthThreshold (':' , '\"')";
final String RGB_THRESHOLD_KEY = "rgbThreshold  ('-' , '+')";
final String ENABLE_OPEN_CV = "enableOpenCV  ('~')";
final String MIN_BLOB_AREA_KEY = "minBlobArea";
final String FILL_IN_BLOBS_KEY = "fillInBlobs ('[')";
final String ENABLE_MESH_CONSTRUCTION = "enableMeshConstruction ('%')";
final String CREATING_SCANNED_MESH = "save mesh ('&')";
final String DEPTH_CONTRAST_KEY = "depthContrast ('q', 'w')";
final String DEPTH_BRIGHTNESS_KEY = "depthBrightness ('e', 'r')";
final

String[] adjustmentVariableNames = {SITE_ID_KEY, USE_SENSOR_CAPTURE_STREAM, UPDATE_SOURCE_IMAGE, DEPTH_MAX_DIST_KEY, DEPTH_THRESHOLD_KEY, RGB_THRESHOLD_KEY, ENABLE_OPEN_CV, MIN_BLOB_AREA_KEY, FILL_IN_BLOBS_KEY, ENABLE_MESH_CONSTRUCTION, CREATING_SCANNED_MESH};

String currSiteID = "";
boolean useSensorCaptureStream = false;
boolean updateSourceImage = true;
float depthMaxDist = 0.0;
float depthThreshold = 0.0;
float depthContrast = 0.0;
float depthBrightness = 0.0;
float rgbThreshold = 0.0;
float rgbContrast = 0.0;
float rgbBrightness = 0.0;
boolean enableOpenCV = false;
float minBlobArea = 0.0;
boolean fillInBlobs = false;
boolean enableMeshConstruction = false;
boolean creatingScannedMesh = false;
boolean saveRGBFrame = false;

boolean tryToUseConnectedSensor = false;
boolean canUseConnectedSensor = false;
PImage sourceImage = null;
PImage depthTextureImage = null;
PImage rgbTextureImage = null;
int[] sourceDepthPixels = null;
PVector[] depthPoints = null;

// these are reset from the context itself below if it's available
int sensorImageWidth = 640; 
int sensorImageHeight = 480;

void setup()
{


        // setup window
    windowWidth = sensorImageWidth * 2 + imageRegionPadding;
    windowHeight = sensorImageHeight + textRegionHeight; 
	
    // set the actual window size, enabling OPENGL
    size(windowWidth, windowHeight, OPENGL);

    // set default values
    setDefaultAdjustmentVariableValues();

if (tryToUseConnectedSensor) {
    // create kinect context and setup options
    context = new SimpleOpenNI(this);
    context.setMirror(true); // mirror is by default enabled
    context.alternativeViewPointDepthToImage(); // enable lining up depth and rgb data    

    // enable depthMap generation (needs to happen after window has been sized)
    if(context.enableDepth() == false) {
	println("Can't open the depthMap, maybe the camera is not connected!");
	canUseConnectedSensor = false;
    } else {
      canUseConnectedSensor = true;
    }
    // enable rgb generation (needs to happen after window has been sized)
    if(context.enableRGB() == false) {
	println("Can't open the rgbMap, maybe the camera is not connected or there is no rgbSensor!");
	canUseConnectedSensor = false;
    }

    // set sensorImageWidth and Height from sensor
    if (context.depthWidth() > 0) {
	sensorImageWidth = context.depthWidth();
    }
    if (context.depthHeight() > 0) {
	sensorImageHeight = context.depthHeight();
    }


    println("sensorImageWidth:  " + sensorImageWidth + "  sensorImageHeight:  " + sensorImageHeight);

    if (context.depthWidth() != context.rgbWidth() || context.depthHeight() != context.rgbHeight()) {
	println("Warning:  SimpleOpenNI depth and rgb images do not have the same dimensions, this will probably be a problem");
    }
}
    // create OpenCV instance and allocate buffer
    opencv = new OpenCV(this);
    opencv.allocate(sensorImageWidth, sensorImageHeight);
}

void draw()
{
    background(200,0,0);

    if (useSensorCaptureStream) {
	// update the cam
	context.update();

	if (enableOpenCV) {
	    // copy depth data into opencv buffer
	    opencv.copy(context.depthImage(), 0, 0, 640, 480, 0, 0, 640, 480);
			
	    // process and render depth data
	    processDepthDataInCurrentOpenCVBuffer();
	
	    // copy rgb data into opencv buffer
	    opencv.copy(context.rgbImage(), 0, 0, 640, 480, 0, 0, 640, 480);
			
	    // process and render RGB data
	    processRGBDataInCurrentOpenCVBuffer();

	} else {

	    // draw depth: use standard depth image map or draw in 3D based on current value of enableMeshConstruction
	    if (enableMeshConstruction) {
		depthPoints = context.depthMapRealWorld();
		processRealWorldPoints();
	    } else {
		// draw depthImageMap
		image(context.depthImage(),0,0);			
	    }    

	    // draw rgbImage
	    image(context.rgbImage(),context.depthWidth() + 10,0);	
	}  

    } else {

	// load image if necessary
	if (updateSourceImage) {
	    updateCurrentSourceData(INPUT_DIRECTORY, currSiteID);
	}

	// use it if we've got it
	if (sourceImage != null) {
			
	    if (enableOpenCV) { // process source image with openCV
				
				// copy depth data into opencv buffer
		if (depthTextureImage != null) {					
		    opencv.copy(depthTextureImage, 0, 0, 640, 480, 0, 0, 640, 480);
		} else {
		    opencv.copy(sourceImage, 0, 0, 640, 480, 0, 0, 640, 480);
		}
				
				
		// process and render depth data
		processDepthDataInCurrentOpenCVBuffer();
				
		// copy rgb data into opencv buffer
		opencv.copy(sourceImage, 640 + imageRegionPadding, 0, 640, 480, 0, 0, 640, 480);
				
		// process and render rgb data
		processRGBDataInCurrentOpenCVBuffer();
				
	    } else {  // don't use openCV

		// draw the current source image (depth + rgb capture)
		image(sourceImage, 0, 0);	       

		if (enableMeshConstruction) {
		    
		    fill(200,0,0);
		    rect(0, 0, sensorImageWidth, sensorImageHeight);
		    processRealWorldPoints();
		} else {
		    // draw depthTextureImage on top if it is present
		    if(depthTextureImage != null) {
			image(depthTextureImage, 0, 0);
		    }		    
		}    				
	    }			
	}
    }

    // draw adjustment variables
    drawAdjustmentVariablesRegion();
}


void updateCurrentSourceData(String fromDir, String siteID) {
    //sourceImage = loadImage(fromDir + "//" + siteID + "\\combined_images_" + siteID + ".jpg");
    sourceImage = loadImage(fromDir + "/" + siteID + "/combined_images_" + siteID + ".jpg");
    updateSourceImage = false;
    println(sourceImage == null ? "failed to load sourceImage" : "loaded source image");
			
			
    // Now replace the source image depth texture with one we create from the raw depth data
    //String[] rawDepthStrings = loadStrings(fromDir + "//" + siteID + "\\depth.json");
    String[] rawDepthStrings = loadStrings(fromDir + "/" + siteID + "/depth.json");
    if (rawDepthStrings != null && rawDepthStrings.length > 0) {
				
	int minValue = 0;
	int maxValue = 0; 
				
	// pull raw depth height map out of JSON data
	try {
	    JSONObject depthData = new JSONObject(rawDepthStrings[0]); 
	    JSONArray depthMap = depthData.getJSONArray("depth_map");
					
	    println("Number of elements in depthMap:  " + depthMap.length());

	    sourceDepthPixels = ArrayUtils.getIntArrayFromJSONArray(depthMap);

	    TextureFactory textureFactory = new TextureFactory(this);
	    depthTextureImage = textureFactory.depthMapToTextureOld(sourceDepthPixels, depthMaxDist, sensorImageWidth, sensorImageHeight);

	    // update actual pixels in depthTextureImage
	    depthTextureImage.updatePixels();

      if (tryToUseConnectedSensor) {
	      depthPoints = OpenNIUtils.realWorldPointsFromDepthMap(sourceDepthPixels, sensorImageWidth, sensorImageHeight, spacing, context);
			}
	} catch (JSONException e) {
	    println ("There was an error parsing the JSONObject.");
	}												
    } else {
	println("Failed to load raw depth strings");
    }
}


void processDepthDataInCurrentOpenCVBuffer() {
	
    opencv.threshold(depthThreshold);
	
    image(opencv.image(), 0, 0, 640, 480);

    Blob blobs[] = opencv.blobs(10, 40*40, 300, true, OpenCV.MAX_VERTICES*4 );
    // draw blob results
    for( int i=0; i<blobs.length; i++ ) {
	beginShape();
		
	if (fillInBlobs) {
	    fill(255, 0, 0);
	} else {
	    noFill();
	}
		
	for( int j=0; j<blobs[i].points.length; j++ ) {
	    vertex( blobs[i].points[j].x, blobs[i].points[j].y );
	}
	endShape(CLOSE);
    }
}

void processRGBDataInCurrentOpenCVBuffer() {

    opencv.threshold(rgbThreshold);

    image(opencv.image(), 640 + imageRegionPadding, 0, 640, 480);

    Blob blobs[] = opencv.blobs(10, width*height/2, 100, true, OpenCV.MAX_VERTICES*4 );

    // draw blob results
    for( int i=0; i<blobs.length; i++ ) {
	beginShape();
		
	if (fillInBlobs) {
	    fill(255, 0, 0);
	} else {
	    noFill();
	}
		
	for( int j=0; j<blobs[i].points.length; j++ ) {
	    vertex( blobs[i].points[j].x + 640 + imageRegionPadding, blobs[i].points[j].y );
	}
	endShape(CLOSE);
    }	
}

void processRealWorldPoints() {

    ModelFactory modelFactory = new ModelFactory(this, depthPoints, context, sensorImageWidth, sensorImageHeight, spacing, depthMaxDist);

    modelFactory.cleanUp();

    if (creatingScannedMesh) {
	String outFilePath =  OUTPUT_DIRECTORY + "//scan_"+random(1000)+".stl";	

	modelFactory.updateModel();
	modelFactory.exportMesh(outFilePath);

	creatingScannedMesh = false;

    } else {
	
	modelFactory.drawDepth();
    }    
}

boolean allZero(PVector p) {
  return (p.x == 0 && p.y == 0 && p.z == 0);
}

void drawAdjustmentVariablesRegion() {

    fill(30, 30, 30);
    rect(0, windowHeight - textRegionHeight, windowWidth, windowHeight);

    int variableNameColumnWidth = 175;
    int rowHeight = textRegionHeight / adjustmentVariableNames.length;
    int leftPadding = 15; 
    int startPosition = windowHeight - textRegionHeight;

    fill(255);  
    for (int i = 0; i < adjustmentVariableNames.length; i++) {
	int yPosition = i * rowHeight + rowHeight/2;

	// draw variable name column
	text(adjustmentVariableNames[i], leftPadding, startPosition + yPosition);

	// draw variable value column
	text(adjustmentVariableValueForVariableName(adjustmentVariableNames[i]), leftPadding + variableNameColumnWidth, startPosition + yPosition);
    }    

}

void keyPressed() { 
    if (key == '\b') {
	if (currSiteID.length() > 0) {
	    currSiteID = currSiteID.substring(0, currSiteID.length() - 1);
	}
    } else if (key == '\t') {
	if (currSiteID != "") {
	    saveDataForSiteJSON(currSiteID);
	}
    } else if (key == '<' || key == ',') { // depthMaxDist
	if (depthMaxDist - depthMaxDistIncrementValue >= depthMaxDistMinValue) {
	    depthMaxDist -= depthMaxDistIncrementValue;
	    updateSourceImage = true;
	} 
	println("leftSign");
    } else if (key == '>' || key == '.') { // depthMaxDist
	if (depthMaxDist + depthMaxDistIncrementValue <= depthMaxDistMaxValue) {
	    depthMaxDist += depthMaxDistIncrementValue;
	    updateSourceImage = true;
	} 
	println("rightSign");
    } else if (key == ';' || key == ':') {
	if (depthThreshold - depthThresholdIncrementValue >= depthThresholdMinValue) {
	    depthThreshold -= depthThresholdIncrementValue;
	}
    } else if (key == '\'' || key == '"') {
	if (depthThreshold + depthThresholdIncrementValue <= depthThresholdMaxValue) {
	    depthThreshold += depthThresholdIncrementValue;
	}
    } else if (key == '-') { // rgbThreshold
	if (rgbThreshold - rgbThresholdIncrementValue >= rgbThresholdMinValue) {
	    rgbThreshold -= rgbThresholdIncrementValue;	
	}
	println("minus");
    } else if (key == '=' || key == '+') { // rgbThreshold
	if (rgbThreshold + rgbThresholdIncrementValue <= rgbThresholdMaxValue) {
	    rgbThreshold += rgbThresholdIncrementValue;	
	}
	println("plus");
    } else if (key == '~' || key == '`') {
	enableOpenCV = !enableOpenCV;
    } else if (key == '/' || key == '?') {
	if (canUseConnectedSensor) {
	    useSensorCaptureStream = !useSensorCaptureStream;	
	} else {
	    println("Sensor was not initialized correctly, please connect it and restart the program");
	}
    } else if (key == ']' || key == '}') {
	updateSourceImage = true;
	println("Update Source Image");
    } else if (key == '[' || key == '{') {
	fillInBlobs = !fillInBlobs;
    } else if (key == '%') {
	enableMeshConstruction = !enableMeshConstruction;
    } else if (key == '&') {
	creatingScannedMesh = true;
    } else if (key == '*') {
	if (currSiteID.length() > 0 && sourceImage != null && sourceDepthPixels != null && sourceDepthPixels.length > 0) {
	    printDepthArrayToMatrixForCurrenSiteID(sourceDepthPixels);
	}
    } else if (key == 'b') {

	exportCapturedData(INPUT_DIRECTORY, OUTPUT_DIRECTORY + "\\" + "ExportTest");
	//println("saving RGBImage cropped out of combinedImage for site with ID: " + currSiteID);
	//saveRGBImageFromCombinedImageWithSiteID(currSiteID);
    } else {
	currSiteID = currSiteID + key;
    }
}


int depthMaxDistMinValue = 300;
int depthMaxDistMaxValue = 3000;
int depthMaxDistIncrementValue = 50;
int depthMaxDistDefaultValue = 750; // default

int depthThresholdMinValue = 0;
int depthThresholdMaxValue = 255;
int depthThresholdIncrementValue = 1;
int depthThresholdDefaultValue = 125;

int rgbThresholdMinValue = 0;
int rgbThresholdMaxValue = 255;
int rgbThresholdIncrementValue = 1;
int rgbThresholdDefaultValue = 75; // default

int minBlobAreaMinValue = 4;
int minBlobAreaMaxValue = 640 * 480;
int minBlobAreaIncrmentValue = 100;
int minBlobAreaDefaultValue = 100;

boolean enableOpenCVDefaultValue = false;
boolean useSensorCaptureStreamDefaultValue = false;
boolean updateSourceImageDefaultValue = false;
boolean fillInBlobsDefaultValue = true;
boolean enableMeshConstructionDefaultValue = false;

void setDefaultAdjustmentVariableValues() {
    depthMaxDist = depthMaxDistDefaultValue;
    depthThreshold = depthThresholdDefaultValue;
    rgbThreshold = rgbThresholdDefaultValue;
    minBlobArea = minBlobAreaDefaultValue;

    enableOpenCV = enableOpenCVDefaultValue;
    useSensorCaptureStream = useSensorCaptureStreamDefaultValue;
    updateSourceImage = updateSourceImageDefaultValue;
    fillInBlobs = fillInBlobsDefaultValue;
    enableMeshConstruction = enableMeshConstructionDefaultValue;
}


/**
   Prints the Depth data as JSON in the following format:
   {"location_id" : 27, "depth_map" : [0, 1, 2]}
*/
void saveDataForSiteJSON(String siteID) {
	
    if (useSensorCaptureStream && canUseConnectedSensor) {
	String fileName = OUTPUT_DIRECTORY + "//" + currSiteID + "\\depth.json"; //"siteID\\depth_" + siteID + ".json";
	println("Creating file:  " + fileName);
	PrintWriter depthOut = createWriter(fileName);

	depthOut.print("{");
	printJSONStringStringKeyValuePair("location_id", siteID, depthOut);
	depthOut.print(", ");
	printJSONStringIntKeyValuePair("depth_width", context.depthWidth(), depthOut);
	depthOut.print(", ");
	printJSONStringIntKeyValuePair("depth_height", context.depthHeight(), depthOut);
	depthOut.print(", ");
	printJSONStringIntKeyValuePair("rgb_width", context.rgbWidth(), depthOut);
	depthOut.print(", ");
	printJSONStringIntKeyValuePair("rgb_height", context.rgbHeight(), depthOut);
	depthOut.print(", ");
	depthOut.print("\"depth_map\"");
	depthOut.print(" : ");
	printJSONArrayToOutput(context.depthMap(), depthOut);
	depthOut.print("}");
	depthOut.flush();
	depthOut.close();	
    }
	
    SaveJpg(OUTPUT_DIRECTORY + "//" + currSiteID + "\\combined_images_" + currSiteID + ".jpg");

}

void saveRGBImageFromCombinedImageWithSiteID(String fromDir, String siteID, String toDir) {

    println("saveRGBImageFromCombinedImage");
     
    String combinedImagePath = fromDir + "\\" + siteID + "\\combined_images_" + siteID + ".jpg";

    PImage combinedImage = loadImage(combinedImagePath);
	
    String outputFileName = toDir + "\\" + siteID + "\\rgb.jpg";

    saveSubimageJPGFromImage(combinedImage, outputFileName, 640 + imageRegionPadding, 0, 640, 480);
}

void saveCurrentDepthTextureIntoDirectory(String toDir) {
    saveSubimageJPGFromImage(depthTextureImage, toDir + "//depth.jpg", 0, 0, 640, 480);
}

void exportCapturedData(String fromDir, String toDir) {

    String[] sites = {"27", "271", "30", "343", "342", "341", "34"};

    for (int i = 0; i < sites.length; i++) {
	exportSite(fromDir, sites[i], toDir);
    }
}

void exportSite(String fromDir, String siteID, String toDir) {
    
    String completePath = fromDir + "\\" + siteID;

    saveRGBImageFromCombinedImageWithSiteID(fromDir, siteID, toDir);
    updateCurrentSourceData(fromDir, siteID);

    // export depth texture

    // export model	    
}

// This function returns all the files in a directory as an array of File objects
File[] listFiles(String dir) {
    File file = new File(dir);
    if (file.isDirectory()) {
	File[] files = file.listFiles();
	return files;
    } else {
	// If it's not a directory
	return null;
    }
}

// This function returns all the files in a directory as an array of Strings  
String[] listFileNames(String dir, boolean onlyReturnDirectories) {
  File file = new File(dir);
  if (file.isDirectory() || !onlyReturnDirectories) {
    String names[] = file.list();
    return names;
  } else {
    // If it's not a directory
    return null;
  }
}

void printContentsOfDirectory(String dir) {
    String[] fileNames = listFileNames(dir, false);
    for (int i = 0; i < fileNames.length; i++) {
	println(fileNames[i]);
    }
}

void printDepthArrayToMatrixForCurrenSiteID(int[] array) {
  String fileName = OUTPUT_DIRECTORY + "//" + currSiteID + "\\depth2D.csv"; 
  println("Creating file:  " + fileName);
  PrintWriter out = createWriter(fileName);

  for (int y = 0; y < sensorImageHeight; y++) {
    for (int x = 0; x < sensorImageWidth; x++) {
      if (x == 0) {
        out.print(array[y * sensorImageWidth]);
        } else if (x == sensorImageWidth - 1) {
          out.print(", " + array[sensorImageWidth * y + x]);
          out.println("");
          } else {
            out.print(", " + array[sensorImageWidth * y + x]);
          }   
        }
      }
    }

void printJSONArrayToOutput(int [] array, PrintWriter out) {
    out.print("[");
    for (int i = 0; i < array.length; i++) {
	if (i == 0) {
	    out.print(array[0]);  
	} else {
	    out.print(", " + array[i]);
	}
    }
    out.print("]");
}

void printJSONStringStringKeyValuePair(String key, String value, PrintWriter out) {
    out.print("\"" + key + "\"");
    out.print(" : ");
    out.print("\"" + value + "\"");
}

void printJSONStringIntKeyValuePair(String key, int value, PrintWriter out) {
    out.print("\"" + key + "\"");
    out.print(" : ");
    out.print(value);
}



void SaveJpg(String fname){
    ByteArrayOutputStream out = new ByteArrayOutputStream();
    BufferedImage img = new BufferedImage(width, height, 2);
    img = (BufferedImage)createImage(width, height);
    loadPixels();
    for(int i = 0; i < width; i++)
	{
	    for(int j = 0; j < height; j++)
		{
		    int id = j*width+i;
		    img.setRGB(i,j, pixels[id]); 
		}
	}
    try{
	JPEGImageEncoder encoder = JPEGCodec.createJPEGEncoder(out);
	encoder.encode(img);
    }
    catch(FileNotFoundException e){
	System.out.println(e);
    }
    catch(IOException ioe){
	System.out.println(ioe);
    }
    byte [] a = out.toByteArray();
    saveBytes(fname,a);
}


void saveSubimageJPGFromImage(PImage image, String fname, int x, int y, int w, int h){

    println("saveSubimageJPGFromImage:  " + fname);

    ByteArrayOutputStream out = new ByteArrayOutputStream();
    BufferedImage img = new BufferedImage(image.width, image.height, 2); // 2 for TYPE_INT_ARGB from BufferedImage constants
    img = (BufferedImage)createImage(image.width, image.height); // redundant?
    image.loadPixels();    

    for(int i = 0; i < image.width; i++) {
	for(int j = 0; j < image.height; j++) {
	    int id = j*image.width+i;
	    img.setRGB(i,j, image.pixels[id]); 
	}
    }

    BufferedImage subimage = img.getSubimage(x, y, w, h);

    try{

	/*   ImageIO approach (png save not working yet)
	File outputfile = new File(fname);
	outputfile.mkdirs();
	outputfile.createNewFile();
	ImageIO.write(subimage, "png", outputfile);
	*/


	JPEGImageEncoder encoder = JPEGCodec.createJPEGEncoder(out);
	encoder.encode(subimage);
    }
    catch(FileNotFoundException e){
	System.out.println(e);
    }
    catch(IOException ioe){
	System.out.println(ioe);
	ioe.printStackTrace();
    }
    byte [] a = out.toByteArray();
    saveBytes(fname,a);
    println("savedBytes to:  " + fname);
}


String adjustmentVariableValueForVariableName(String adjustmentVariableName) {

    if (adjustmentVariableName.equalsIgnoreCase(SITE_ID_KEY)) {
	return currSiteID;
    } else if (adjustmentVariableName.equalsIgnoreCase(USE_SENSOR_CAPTURE_STREAM)) {
	return useSensorCaptureStream ? "True" : "False";	
    } else if (adjustmentVariableName.equalsIgnoreCase(UPDATE_SOURCE_IMAGE)) {
	return "N/A";
    } else if (adjustmentVariableName.equalsIgnoreCase(DEPTH_MAX_DIST_KEY)) {
	return Float.toString(depthMaxDist); 
    } else if (adjustmentVariableName.equalsIgnoreCase(RGB_THRESHOLD_KEY)) {
	return Float.toString(rgbThreshold);
    } else if (adjustmentVariableName.equalsIgnoreCase(MIN_BLOB_AREA_KEY)) {
	return Float.toString(minBlobArea);
    } else if (adjustmentVariableName.equalsIgnoreCase(ENABLE_OPEN_CV)) {
	return enableOpenCV ? "True" : "False";
    } else if (adjustmentVariableName.equalsIgnoreCase(DEPTH_THRESHOLD_KEY)) {
	return Float.toString(depthThreshold);
    } else if (adjustmentVariableName.equalsIgnoreCase(FILL_IN_BLOBS_KEY)) {
	return fillInBlobs ? "True" : "False";
    } else if (adjustmentVariableName.equalsIgnoreCase(ENABLE_MESH_CONSTRUCTION)) {
	return enableMeshConstruction ? "True" : "False";
    } else if (adjustmentVariableName.equalsIgnoreCase(CREATING_SCANNED_MESH)) {
	return "N/A";
    } else {
	return "Unknown NO Match";
    }
}
