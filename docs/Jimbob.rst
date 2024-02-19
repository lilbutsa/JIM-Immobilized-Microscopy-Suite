Jimbob
======

**Jimbob** is a plugin for Micromanager designed to allow uses to get real time feedback on how data will look when converted to traces. It is a lightweight version of the JIM generate traces pipeline, which cuts a lot of corners to speed up processing considerably. On most data, the output of Jimbob will be nearly identical to the full JIM, however there are limitations to its usage.

Jimbob Limitations
------------------

**Single Detection Region**

**No Image Tranformation** Jimbob assumes images are already correctly orientated. 

**No Image Alignment** Jimbob designed for data collected using sequential acquisition

**Single Iteration Drift Correction**

**Bounding Box used for ROIs**




Installing Jimbob
-----------------

To run Jimbob in micromanager, copy **Jimbob.jar** from the Jimbob folder and paste it into the **mmplugins** folder, located in your micromanager installation folder. By default, this folder location is C:\Program Files\Micro-Manager-2.0\mmplugins

**WARNING** Do NOT put it in the **plugins** folder, make sure it is the **mmplugins** folder.

Parameters
----------

**File Select** - Drop Down menu conatins all image stacks currently open in micromanager. The current position in the stack the when the stack is selected here is the position used for the other sections.

**Align ROI size** - *Size of Region of Interest for Alignment* : The region at the centre of the image that will be used for alignment. Has to be a power of 2 (ie 256,512,1024). Larger areas will be more robust but also slower to calculate.

**Max Shift** - *Maximum Shift allowed for Dift Correction* : Limit drift correctiion to correct by less than this value. This can halp avoid abborent alignment with weak signals.

**Drift Correct Detection** - *Drift Correct Image Used for Detection* : Whether or not to drift correct the stack before creating the image used for detection

**Channel** - *Channel to Use for Detection and Alignment* : Set to 0 to detect using the sum of all channels, otherwise 1 for channel 1 etc.

**Start Frame** - *Detection Start Frames* : first frame of the reference region for detection for each channel

**End Frame** - *Detection End Frames* : last frame of reference region. Negative numbers go from end of stack. i.e. -1 is last image in stack




**Cutoff** - *Threshold Cutoff* :  The cutoff for the initial thresholding. Typically in range 0.5-4

**Min Eccentricity** - *Minimum Eccentricity of ROIs* : Eccentricity of best fit ellipse goes from 0 to 1 - 0=Perfect Circle, 1 = Line. Use the Minimum to exclude round objects. Set it to any negative number to allow all round objects

**Max Eccentricity** - *Maximum Eccentricity of ROIs* : Use the maximum to exclude long, thin objects. Set it to a value above 1 to include long, thin objects  

**Min Count** - *Minimum Pixel Count* : Minimum number of pixels in a ROI to be counted as a particle. Use this to exclude speckles of background

**Max Count** - *Maximum Pixel Count* : Maximum number of pixels in a ROI to be counted as a particle. Use this to exclude aggregates

**Min Dist From Edge** - *Minimum Distance from Edge of Image* : Exclude particles that are closer than this to the edge of the image (in pixels). Make sure this value is larger than the maximum drift. 25 works well in most cases

**ROI Padding** - *Bounding Box Padding for ROI* : Distance to expand the bounding box of the ROIs by to make sure all flourescence from the ROI is measured.

**Background Padding** - *Distance to expand for Background* : Distance to expand beyond the bounding box of and ROI to measure the surrounding background. Note that any parciles in this region will cause this particle to be excluded.




**Drift Correct** - *Drift Correct Checkbox* : Whether or not to drift correct the stack before measuring traces. 

**Display Stack** - *Display the aligned Image Stack* : Whether to display the image stack after alignment. Warning: Do not select this if there is not enough ram to store the image stack!

**Page Number** - *Page Number of Montage to Display* : Which page of example traces to display.

**Normalize** - *Normalize Multi-Channel Data Traces* : Multi-Channel data can have very different intensities making it hard to read on a single plot. Selecting this will normalize the traces of all traces to the same height to make it easier to view. This does not affect the saved traces.

**Time per frame** - *Time between frames* : The time between each frame in the image stack. This value is just used to scale the x-axis of trace plots.

**Units** - *Units of time between frames* : The units used for the time between each frame in the image stack. This value is just used to label on the x-axis of traces.

**Save Traces** - *Save Traces Checkbox* : Whether fluorescent and background intensity traces should be saved as a csv. Example trace montage, and mean traces will also be saved.

**Browse** - *Save file Dialog* : Opens a file Dialog to select the folder that traces should be saved to.

**Folder Path** : The currently selected save folder path


**Channel to Step Fit** : The channel in the image stack that should be step fit to analyse step times and step heights
**Step Fit in Batch** : Whether to step fit traces when batch processing all positions
