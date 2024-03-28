***************************
Tutorial 3 - Photobleaching
***************************

Basic Experimental Setup
========================
The objective of this experiment is to calculate the absolute intensity of a single fluorescently labelled molecule. In addition, this experiment calculates the bleaching rate of the fluorophores and estimates oligomeric states of the molecules. 

This experiment can be used to calculate conversion factors which can be used in future experiments to convert measured fluorescent intensities to numbers of bound molecules. Measuring the photobleaching rate also allows users to calculate the bleaching rate that can be used in future kinetic binding experiments to calculate how many frames can be acquired before bleaching becomes significant.
Typical Experimental Procedure
Note: Use the exact same buffer for this experiment that you want to use for future binding experiments. If you are planning on using anti-bleaching agents (PCA/PCD, Glucose oxidase, Trollox etc) make sure you use them in this experiment as well so that measured values are consistent between experiments.
  
- Clean a coverslip by sonication in ethanol, followed by water then 1M NaOH then water for 15 minutes each or any other preferred cleaning method. 

- Glow discharge the coverslip using a plasma cleaner. 

- Place the coverslip into a coverslip holder (such as a Chamlide chamber) that prevents liquid from running off the edge of the slide

- Add 100 - 1000 ul of the fluorescently labelled molecule at a low concentration (10 pM for charged sticky proteins, 100 pM for Normal proteins up to 4 nM may be needed) 

- Leave to bind for a minute.

- Wash with several volumes of wash buffer to remove unbound molecules.

- Wash buffer is then discarded and replaced with fresh wash buffer to keep molecules hydrated. 

- Image coverslip on the microscope. Molecules density should be as high as possible while still being clearly distinct from each other so their fluorescence intensities do not overlap.

- A photobleaching image stack is then collected by exposing a field of view with the same laser power setting used during the actual experiment but at higher exposure (typically 100-500 ms or higher). The exposure just needs to be long enough to see individual molecules (good signal to noise ratio).

- Image enough frames such that approximately 90% of fluorophores would be bleached. If this is less than 20 frames then decrease exposure time. If this is more than 300 frames, then increase the exposure.

- Image multiple fields (5-10) to measure variability within the sample and consistency of analysis.

Analysing Using JIM
===================

A folder containing 3 examples fields of view from a single molecule photobleaching experiment can be found in the folder “Examples_To_Run\3_Photobleaching”. These files are labelled Photobleaching_Example_1.tif, Photobleaching_Example_2.tif and Photobleaching_Example_3.tif. 

Opening any of these files (for our example Photobleaching_Example_1.tif) will show a number of single molecules that bleaching over time:

.. image:: tut_3/tut_3_montage.jpg
  :width: 600
  :alt: Photobleaching Montage

It should be noted that this is a very minimal example. For each image stack, the field of view has been cut down to 500x500 pixels and every second frame has been taken in order to minimize file sizes. In a normal experiment, we would collect more fields of view (~10) each with a larger image size (1000-2000 pixels squared) and more frames (~100-200 frames) which will increase the quality of all fits dramatically.

Further, the quality of experiment here is pretty poor. The density of particles in this example is pretty low, and the autofocus is quite shaky (particles go in and out of focus a bit). This should be a representation of the lowest quality data that is required for this kind of analysis.

Generating Traces
=================

As with every dataset analysed by JIM, the first step in analysing single molecule photobleaching experiments is to convert the image stacks into traces. To do this, run the Begin_Here_Generate_Traces script. This tutorial will go through the running of this script but will do so reasonably concisely. More details can be found in Tutorial 1. The key difference here is that we will also use the last two sections of the script to batch analyse all three fields of view.

0) Import Parameters
--------------------

The parameters used for generating traces in this tutorial can be loaded by running this section and selecting the file *Examples_To_Run\3_Photobleaching\\Tutorial_3_Final_Parameters.csv*

The final parameters for generating traces in this tutorial are also in a table `here <https://jim-immobilized-microscopy-suite.readthedocs.io/en/latest/tut_3_photobleaching.html#final-parameters>`_


1) Select Input File and Create a Folder for Results
----------------------------------------------------

Run this section, set : 

**Additional Extensions to Remove** = 0 

and select *Photobleaching_Example_1.tif*. 

This will create the analysis folder Example_Data\Tutorial_3_Single_Molecule_Photobleaching\Photobleaching_Example_1'

2) Organise Channels
--------------------

The data is all contained in a single file so we can set **Multiple Files Per Image Stack** to false;

This is single channel data so set **Number of Channels** to 1. We know it is in order so we can **Disable Metadata**. We want to use the entire dataset so we set **Stack Start Frame** to 1 and **Stack End Frame** to -1.

We don't need to orientate the data at all so we can leave **Channels to Transform** empty. When this is the case, the last three parameters (**Vertical Flip**,**Horizontal Flip** and **Rotate**) are not used so can be set to anything.


3) Drift Correct
----------------

Run drift correction with 1 iterations and aligning to the first 5 frames of the image stack (where all particles are present), by using the parameters:

**Iterations** = 1

**alignStartFrame** = 1

**alignEndFrame** = 5

**maxShift** = 10

Which should generate an after Drift Correction image of:

.. image:: tut_3/tut_3_drift_after.PNG
  :width: 600
  :alt: After Drift Correction

There is very minimal drift in this experiment. Opening *Alignment_Channel_1.csv* we see that the calculated drifts are all less than a pixel, so drift correction isn't technically needed here.


4) Make a Sub-Average of the Image Stack for Detection
------------------------------------------------------

We want to detect particles using the part of the image stack where the vast majority of the particles are present. This optimal range is typically from 1 through to when around 10% of the particles have bleached (this value is actually measured quantitatively in the Fitting Bleaching Times section) but in most cases an approximate value is reasonably robust. 

In the extremes, making this value too large will cause a decrease in the detection of fast bleaching particles (which will bias the Bleaching Times distribution). Conversely, making this value too low will make it difficult to detect dim particles which will bias the Step Height Detection.

For this example, we are going to use the first 5 frames by setting:

**useMaxProjection** = false

**detectionStartFrame** = 1

**detectionEndFrame** = 5

**channelWeights** = 1

Which should give the Sub-average to use for detection image of:

.. image:: tut_3/tut_3_image_for_detection.PNG
  :width: 600
  :alt: Image for Detection

5) Detect Particles
-------------------

For this data set, a cutoff of 1.7 selects all of the particles in the detection image and only a small amount of background :

.. image:: tut_3/tut_3_initial_detection.PNG
  :width: 600
  :alt: Initial Thresholding

We can then filter out all particles within 10 pixels of the edge (left, right, top and bottom = 10), all particles with less than 10 pixels to eliminate background spikes (minCount = 10) and all particles with an eccentricity above 0.4 or pixel count above 100 to get rid of clumps of particles (maxEccentricity = 0.4 and maxCount = 100). We also want to exclude particles that are too close to each other where the flourescence from one particle could spill over into the others region by setting minSeparation = 5. 

In summary, the detection parameters should be:

**Min. dist. from left edge** = 10

**Min. dist. from right edge** = 10

**Min. dist. from top edge** = 10

**Min. dist. from bottom edge** = 10

**Min. pixel count** = 10**

**Max. pixel count** =100

**Min. eccentricity** = -0.1

**Max. eccentricity** = 0.4

**Min. length** = 0

**Max. length** = 10000000

**Max. dist. from linear** = 10000000

**Min. separation** = 5;

Which should give:

.. image:: tut_3/tut_3_final_detection.PNG
  :width: 600
  :alt: After Filtering

Note that the white (detected) spots all look reasonable, and that the yellow excluded spots are either close to the edge, too close to each other, two particles that have been detected as one, or are small background guff.

6) Additional Background
------------------------

This section is used to cut around particles that appear after the first 5 frames when calculating background regions. To do this, we want to use a max projection so it doesn't matter when particles come in, or if they are only present for a short period of time. We also want to look across the entire image stack (start frame = 1, end frame =-1). Finally, a threshold of 2 seems to detect all particles.

To summerise, set:

**Detect Additional Background** = true

**Use Max Projection** = true

**Start Frame** = 1

**End Frame** = -1

**Weights** = 1 

**Threshold Cutoff** = 2


7) Expand Regions
-----------------

The default parameters are fine for this section:
foregroundDist = 4.1
backInnerDist = 4.1
backOuterDist = 20

Which gives:

.. image:: tut_3/tut_3_Expansion.PNG
  :width: 600
  :alt: Expanded Regions

Note that the fluorescent signal (yellow) is neatly contained within the foreground region (green) showing that these parameters are good for this data.

8) Calculate Traces
-------------------

Running this section will calculate the traces for each region that can be found in the file:
*\Examples_To_Run\3_Photobleaching\Photobleaching_Example_1\Channel_1_Fluorescent_Intensities.csv*. It will also save a summary of the parameters used in the file: *\Examples_To_Run\3_Photobleaching\Photobleaching_Example_1\Trace_Generation_Variables.csv*. 


9) View Traces
--------------

Setting pageNumber = 1 and running this section will show an image with the number of each particle:

And the traces for the first 28 particles:

Note that the majority of traces are displaying the characteristic step as expected. There are also a fair few particles (1,2,25 etc) that remain bright for the entire experiment, suggesting that we should have imaged more frames (or in this case had larger example files...).

10) Detect files for batch
-------------------------

This section detects all the files that we want to analyse with the same parameters.There are two ways that the files can be arranged. All folders that contain images can be placed into a master folder. When this is the case set filesInSubFolders = true. 

Alternatively, all image files can be directly placed into a master folder. This is the case for the example photobleaching files where Photobleaching_Example_1.tif, Photobleaching_Example_2.tif and Photobleaching_Example_3.tif are all in the same master folder (\Example_Data\Tutorial_3_Single_Molecule_Photobleaching\). Set:

filesInSubFolders = false

And run the section, then select the master folder: \Example_Data\Tutorial_3_Single_Molecule_Photobleaching\
The three files should be detected.

11) Batch Analyse
----------------

In the case where some of the files in the folder have already been analysed, the parameter overwritePreviouslyAnalysed can be set to false to avoid reanalysing image stacks that already have traces.
In this case, we don’t care, so set:

overwritePreviouslyAnalysed = true

And run the section.

Once complete, there should be an analysis folder for each of the photobleaching examples, and in each folder there should be all of the trace generation analysis, in particular the Channel_1_Fluorescent_Intensities.csv which contains the traces for that files.  

Now that we have generated traces for our image stacks we can analyse the traces using Photobleaching analysis (the Single_Molecule_Photobleaching script).


Single-Molecule Photobleaching Analysis of Traces
=================================================

1) Select Input Folder
----------------------
Similar to the batch processing for generating single-channel traces, this section detects all the files that we want to perform single-molecule photobleaching analysis on.

There are two ways that the original image files can be arranged:

1) All folders that contain images can be placed into a master folder. When this is the case set filesInSubFolders = true. 

2) All image files can be directly placed into a master folder. This is the case for the example photobleaching files where Photobleaching_Example_1.tif, Photobleaching_Example_2.tif and Photobleaching_Example_3.tif are all in the same master folder (\Example_Data\Tutorial_3_Single_Molecule_Photobleaching\). Set:

filesInSubFolders = false

And run the section, then select the master folder: \Example_Data\Tutorial_3_Single_Molecule_Photobleaching\
The three files should be detected.
2) Stepfit Traces
This section performs change point analysis to heuristically determine whether or not a step occurs in a trace. To do this, random permutations of the trace are generated, to work out the probability that a change as big as in the data occurs by chance.

There are two important points for this method:
As the probabilities are determined by randomly generating traces, the calculated probabilities change each time the program runs.
The higher the number of permutations generated, the more accurate the calculated probability and the less drastically values change from repeat to repeat.

Typically using 1000 iterations is sufficient to get a good approximation of each step probability, and by 10000 iterations, probability estimates will only change by a fraction of a percent each time, which should be good enough for most cases, but maybe slow if there are more than a few thousand traces to analyse.

In this case, we will set:
stepfitIterations = 10000
And run this section to step fit all data.

After step fitting is complete, within each image files trace analysis folder (eg. \Example_Data\Tutorial_3_Single_Molecule_Photobleaching\Photobleaching_Example_1\) there should be a file called Stepfit_Single_Step_Fits.csv. This file contains all of the information about the single step fits for each trace. For example 1 it should look similar to:

Note that the calculated probabilities will be slightly different each time, but should be quite similar to the values shown here.

Each trace number here corresponds to the same trace as in the Detected_Filtered_Region_Numbers.tif image, and the corresponding measurements Detected_Filtered_Measurements.csv and Channel_1_Fluorescent_Intensities.csv from generating single-channel traces.
3) View Single Step Filters
The next step is to take the step fit probability information and filter traces to select for traces that have a single step. There are three parameters that we can use to achieve this:

minFirstStepProb - the probability that there is a step. If the initial step is very short then this value can be quite low. Setting this to 50% seems to work pretty well in most cases. 
maxSecondMeanFirstMeanRatio - the ratio of the mean after the step to the mean before the step. Alternatively, this can be thought of as one minus the percent of the initial intensity that the step has to be bigger than.
maxMoreStepProb - How probable it can be that there are additional steps. The step detection is typically very sensitive, so it is normally fine to set this as anything less than certain (like 99%).

This section lets you select the file and the page of traces to view. Setting these values to:    fileToCheck = 1
pageNumber = 1
Will display the first page of traces from the first image stack.

As an initial guess use the settings:

minFirstStepProb = 0.5
maxSecondMeanFirstMeanRatio=0.25
maxMoreStepProb=0.99

Running this section will display two pages. One of the traces that have been included as single steps and one page of traces that have been excluded.

With these parameters the single step traces page should look like:


And excluded traces should look like:


Once suitable parameter values have been found we can move onto the next section. In this case we will use these initial values.

4) Filter All Files for Single Steps
Running this section applies the filters from above to all the image files. Once it has run, In the trace analysis of each folder there will four extra files:

Single_Step_Traces.csv - Traces containing only single steps.
Single_Step_Step_Fit.csv - The respective step fits for these traces.
Multi_Step_Traces.csv - Traces that were excluded by the filters.
Multi_Step_Step_Fit.csv - The respective step fits for the excluded traces.

The original trace numbers for each trace can be found in the first column of the Step fit files. This can be helpful to relate these traces back to the original position images etc.
5) Fit Bleach Times
This section fits the bleaching survival curve (the number of particles that are still bright after each frame) with an exponential to determine the bleach rate. 

Several factors can contribute to an underrepresentation of fast bleaching particles. In particular, taking a larger average window for the detection image when making traces, and setting a high minFirstStepProb in the step filtering. 

It is also possible that the photobleaching sample is not perfectly clean and so will have a small population of contaminants that will bleach slowly.

To overcome these problems, there are two parameters that let you filter out a percent of the highest and lowest values, to exclude these regions from fitting. For this case, the sample is clean (there are no significant slower bleaching contaminants so we can set the minimum cutoff to 0 to include all slow events. In general, there tends to be a slight underrepresentation of fast bleaching states so we can exclude the first 10%  of bleaching times. Combined, we do this by setting:

expYMinPercent = 0;
expYMaxPercent = 0.9;

These parameters should work well for the vast majority of fitting cases.

Running this section should display an image of the pooled fit of all bleaching times, which looks like:

That the exponential doesn’t plateau further indicates that we should have taken more images for our photobleaching. However, the majority of the curve is present, so it will still give a reasonably accurate value for the bleaching rate.  

Running this section will have made a folder called Compiled_Photobleaching_Analysis in the master folder (Example_Data\Tutorial_5_Single_Molecule_Photobleaching). In this folder, there are two csvs of particular interest if you want to be able to plot this data for your own publications.

Bleaching_Survival_Curves.csv contains the experimental data for the bleaching survival curves for each individual field of view as well as the pooled data. It should look like:


In this file, each first line (i.e. Lines 2,4,6 and 8) is the frame number and each second line (Lines 3,5,7 and 9) is the number of unbleached particles after that number of frames. The first three data sets here correspond to each of the three fields of view and the fourth dataset is the pooled dataset. For example, we can plot the survival curve for the first field of view by setting line 2 as our x points and line 3 as our y points which gives:



The file names of each field of view are found in Bleaching_File_Names.csv.

The exponential fits for each curve are found in Bleaching_Survival_Curves_ExpFit.csv which should look like:

Here, the offset corresponds to the number of unbleached particles at the end of the acquisition, Amplitude is the number of bleached and unbleached and the exponent is the bleaching rate for that field of view. So for the first field of view, the fit equation is -16.9245+222.2493*E^(-0.054105 t)

Also in the Compiled_Photobleaching_Analysis is the high-resolution image Bleaching_Rate.png of the pooled bleaching curve. 
6) Fit Step Heights
This section fits the step height distribution for the single-step traces, as these should represent the intensity of single molecules for this system.

We look to fit a gaussian to the peak of this distribution, although the actual distribution will typically be skewed with a right hand tail, so we can exclude a percentage of each extreme to just fit the peak.

To do this, set:

gausYMinPercent = 0;
gausYMaxPercent = 0.9;

And run the section, which should then display the pooled intensity histogram:

A high-resolution version of this image is saved in the Compiled_Photobleaching_Analysis folder as Step_Height_Distribution.png.

Just as with the bleaching fits, the underlying data and fits are saved to the Compiled_Photobleaching_Analysis folder. 

Step_Heights.csv contains all of the raw stepheights in case the user wants to use their own binning to form the histogram. Each line is the steps heights for a field of view with the final line being the pooled data.

Step_Heights_Histograms.csv contains the histograms of step heights. It should look like:





Here each first line (2,4,6,8) are the x axis (particle intensities) and every second line is the y-axis (Probability Density Function value). For example, plotting the first field of view (lines 2 and three) gives:



Finally, Step_Heights_GaussFit.csv contains all the gaussian fits for each distribution as well as some other basic statistics on each distribution (mean standard deviation and median). It should look like:

Each Line is a field of view except the final line which is for the pooled data.

The normal distribution, which the experimental histograms should overlay with is given by:


Where μ is the Gaussian Mean and σ is the Gaussian Standard Deviation.


7) Find Signal to Noise
We can get a measure of the signal to noise in the traces by looking at the ratio between the step height versus the standard deviation of the trace once the step has been subtracted. This gives us a measure of how large the single molecule intensity is compared to average fluctuations in the trace. Weak signals will typically have values around 1, strong signals will be above 2.

Running this section will display the pooled histogram of signal to noise ratios:

A high-resolution version of this image is saved in the Compiled_Photobleaching_Analysis folder as Signal_to_Noise.png.

Similarly to step heights, all underlying data values are saved in Signal_to_Noise.csv. With the histograms for them in Signal_to_Noise_Histograms.csv.
8) Initial Particle Intensity Distribution
If we take the single molecule intensity as the mode of the step height, we can then take every particle in our original image stack and work out what the initial intensity (the intensity of every particle in frame 1) of those particles are in terms of number of molecules. This will tell us whether we have a large dimer or trimer population.

Running this section will display the pooled histogram of particle intensities which should look like:

A high-resolution version of this image is saved in the Compiled_Photobleaching_Analysis folder as All_Particle_Intensities.png.

Similarly to step heights and signal to noise, all underlying data values are saved in Initial_Intensities.csv. With the histograms for them in Initial_Intensities_Histograms.csv.

9) Create a Combined Figure and Summary Table

Finally, we combine the high resolution images into a single figure to make a compact summary of the photobleaching distributions and generate a Table showing the key statistics from all the fits.

Running this section should display the combined figure:


A high-resolution version of this image is saved in the Compiled_Photobleaching_Analysis folder as Combined_Figure.png.

A table will also be displayed which should look like:


For each measure, the value for each field of view is shown, as is the mean and standard deviation for all field of views, as well as the measure for all data pooled together. The pooled value is normally the most accurate, but the mean and standard deviation is helpful in approximating an error for each value.

The measures in this table include:
Num_of_Particles - the total number of traces that were extracted from each field of view
Num_of_Single_Steps - the number of traces determined to contain single steps
Bleach_Rate_per_frame - the bleach rate of the sample in units of per frame
Half_Life - the half life of bleaching in frames. The number of frames when 50% of particles are bleached
Ten_Percent_Bleached - The number of frames when 10% of bleaching has occurred. This value can be used as a guide to determine how many frames can be acquired before there is significant photobleaching in subsequent experiments.
Gauss_Fit_Mean - the mean of the gaussian fit for the single particle intensity
Gauss_Fit_Std_Dev - the standard deviation of the gaussian fit for the single particle intensity
Mean_Step_Height - The mean of the raw step height data.
Std_Dev_Step_Height - The standard deviation of the raw step height data
Median_Step_Height - The median of the raw step height data.
Mode_Step_Height - The mode of the raw step height data. Binning is determined using the Freedman–Diaconis rule.
Mean_Signal_to_Noise - The mean of each step height divided by their respective traces residual standard deviation.
Submonomer_Fraction - The fraction of all particles intensities in frame 1 that are less than half the mode step height.
Monomer_Fraction - The fraction of all particles intensities in frame 1 that are between 0.5 to 1.5 times the mode step height.
Dimer_Fraction - The fraction of all particles intensities in frame 1 that are between 1.5 to 2.5 times the mode step height.
Higher_Order_Fraction - The fraction of all particles intensities in frame 1 that are greater than 2.5 times the mode step height.

This table is saved in  the Compiled_Photobleaching_Analysis folder as Bleaching_Summary.csv.

The parameters that were used for analysis in this program are saved in the Compiled_Photobleaching_Analysis folder as Single_Molecule_Photobleaching_Parameters.csv.
