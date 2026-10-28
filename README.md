# tangible-landscape-install
Install scripts for Tangible Landscape.

| script  | OS  | Kinect  |
|---|---|---|
| install_Ubuntu-24.04_femto-bolt.sh | Ubuntu 24.04  | Orbbec Femto Bolt |
| install_Ubuntu-24.04_k4a.sh        | Ubuntu 24.04  | Azure Kinect DK |
| install_Ubuntu-24.04_xbox-one.sh   | Ubuntu 24.04  | Kinect for Xbox One |
| install_Ubuntu-22.04_k4a.sh        | Ubuntu 22.04  | Azure Kinect DK |
| install_Ubuntu-22.04_xbox-one.sh   | Ubuntu 22.04  | Kinect for Xbox One |

## Docker image for Orbbec Femto Bolt

1. Build and run the image by calling
```cd tangible-landscape-install```
```chmod +x ./run_tangible_landscape.sh && ./run_tangible_landscape.sh```
2. In the container, open GRASS by calling ```grass``` and create a new GRASS project which uses EPSG:3358
3. Open the GRASS Tangible Landscape add-on in the GRASS shell by running ```g.gui.tangible```
4. Input parameters for g.gui.tangible to match the following:
* Blender coupling directory: ```/tmp/tangible-landscape-install/blender-tangible-landscape/Watch```
* Scanning Page
	* Resolutions: ```2mm```
	* Interpolation not binning
	* 3 scans each iteration
* Output Page
	* Save color rasters: ```color_scan```
	* Export folder for Blender coupling: ```/tmp/tangible-landscape-install/blender-tangible-landscape/Watch```
* Activities
	* Configuration: ```/tmp/tangible-landscape-applications/blender5/combined_config.json```
	* Select ```Start activity```
5. Calibrate Tangible Landscape
	* Patch Detection Calibration
		* Place patches for all desired classes on the Tangible Landscape surface and take a single color scan
		* Create a ground truth raster called ```ground_truth``` which has classes for each patch in the original image
		* Run ```i.rgb.his --overwrite red=color_scan_r@PERMANENT green=color_scan_g@PERMANENT blue=color_scan_b@PERMANENT hue=color_scan_h intensity=color_scan_i saturation=color_scan_s``` to generate HIS files for the HIS model.
		* Delete the ```color_scan_i``` raster to eliminate lighting noise.
		* Run ```i.group``` and create a group called ```color_scan_hs``` with ```color_scan_h``` and ```color_scan_s```.
		* Run ```i.svm.train --overwrite group=color_scan_hs@PERMANENT trainingmap=ground_truth@PERMANENT signaturefile=svm_hs_sig@PERMANENT``` to create the signature file for the HIS colorspace.

## Development Notes
* We also need to include the set-up for all the other repositories in this docker container so it always pulls the latest repo on build time. These include the Blender repo, actvities repo, and some of the directories that we need for those 

The current command to run the docker container is:
```xhost +local:docker && docker compose up```

Assuming ```echo $DISPLAY``` is set and returns something similar to ```:0```. 
