********************************************
Tutorial 1 - Single Channel Trace Generation
********************************************

This is an artificial example designed to introduce new users to the basic functionality of JIM and what a standard workflow looks like when working with single channel data. 

There are two versions of this example data - with and without noise. Without noise provides a neat check that the measured intensities correspond to theoretical values. With noise provides a test for the detection limits of the software. 

The raw data for the without noise version is found in *Examples_To_Run\1_Point_Array_No_Noise\Tutorial_1_Jim_Test_Array_No_Noise.tif*. The example with noise is found in *Examples_To_Run\1b_Point_Array_With_Noise\Tutorial_1_Jim_Test_Array.tif*

This tutorial will use the with noise example, however the without noise data can be used with the exact same parameters.

Users are strongly encouraged to open this file with a program like ImageJ to get a feel for what the data looks like. The test array is a tif stack containing 50 images each 256x256 pixels in size. The full image contains a 12x12 array of diffraction limited spots. Each row of spots gets increasingly bright allowing users to experiment with the detection limits of JIM. Every 4 frames, an additional column in the image stack becomes dark, to demonstrate the interplay in detection difficulty between how bright a particle is and how long it is present in images.

.. image:: Tut_1_montage.png
  :width: 600
  :alt: Montage of Tutorial_1_Jim_Test_Array.tif

The basic aim of this tutorial is to analyze the intensities and disappearance of spots over times in this video.

This data is generated in Mathematica using the *\1a_Point_Array_No_Noise\Tutorial_1_Jim_Test_Array.nb* program which is included in the Examples_To_Run folder in case users wish to regenerate the data with different random numbers or modify it. 

This protocol has been implemented in Matlab, Python and ImageJ. 

