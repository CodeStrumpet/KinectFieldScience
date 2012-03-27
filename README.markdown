*Software to aid in using a kinect or other similar sensors for imaging and analysis in scientific field studies*

Steps to get the code up and running
------------------------------------
You will have to install the kinect drivers and openni library.  These are only used for capturing new images however even if you only want to do image analysis, Processing will complain if they aren't present.

Easiest way to install the kinect drivers and openni library is to use ZigFu (get the browser plugin here, it will include everything you need):  http://zigfu.com/en/downloads/browserplugin/

You will also need the following libraries in your processing 'libraries' directory:

http://code.google.com/p/simple-openni/ (if you already installed the kinect drivers and openni library using zigfu you should only need to download the processing library)

https://github.com/agoransson/JSON-processing (put this in your processing sketchbook's 'libraries' directory)

http://ubaa.net/shared/processing/opencv/download/01/opencv_01.zip (goes in your processing sketchbook's 'libraries directory, see url below for instructions on installing openCV on your system)

Then you'll also need to install opencv.  Follow instructions for your platform here:  http://ubaa.net/shared/processing/opencv/



Image showing Adjusted Depth Distance Threshold
-----------------------------------------------
![Depth Distance Threshold](https://github.com/CodeStrumpet/KinectFieldScience/raw/master/ProjectDocs/crusty_dist_threshold.png "Depth distance threshold")

Image showing OpenCV Attempting to find blobs
---------------------------------------------
![OpenCV Enabled](https://github.com/CodeStrumpet/KinectFieldScience/raw/master/ProjectDocs/crusty_opencv1.png "OpenCV Enabled")

Image showing screenshot of early WebGL viewer of the depth data as a mesh with the rgb image applied as a texture
--------------
![Early Terrain](https://github.com/CodeStrumpet/KinectFieldScience/raw/master/ProjectDocs/early_terrain.png "Early Terrain")



