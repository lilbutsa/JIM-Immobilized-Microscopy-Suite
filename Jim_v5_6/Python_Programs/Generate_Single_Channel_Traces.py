import datetime
from sys import platform as _platform
import sys
import os
import tkinter as tk
import matplotlib.pyplot as plt
import matplotlib.image as mpimg
import csv
import numpy as np
from tkinter import filedialog
from PIL import Image



sectionNumber = 7
# Sections
# 1 - Select input file and create a folder for results
# 2 - Drift Correct
# 3 - Make a SubAverage of Frames for Detection
# 4 - Detect Particles
# 5 - Expand Regions
# 6 - Calculate Traces
# 7 - View Traces
# 8 - Detect files for batch
# 9 - Batch Analyse

# ~~~~PARAMETER INPUTS~~~~ #
# 1 - General Parameters
overlayColours1 = [1, 0, 0]
overlayColours2 = [0, 1, 0]
overlayColours3 = [0, 0, 1]

displayMin = 0
displayMax = 2


# 2 - Drift Correct Parameters
iterations = 3
alignStartFrame = 1
alignEndFrame = 5

# 3 - Make a SubAverage of the Image Stack for Detection Parameters
useMaxProjection = False
detectionStartFrame = 1
detectionEndFrame = 25

# 4 - Detect Particles Parameters
cutoff = 0.85  # The cutoff for the initial threshold

# Filtering
left = 10  # Excludes particles closer to the left edge than this (in pixels).
right = 10  # Excludes particles closer to the right edge than this (in pixels). 
top = 10  # Excludes particles closer to the top edge than this (in pixels). 
bottom = 10  # Excluded particles closer to the bottom edge than this (in pixels). 


minCount = 10  # Minimum number of pixels in a region to be included
maxCount = 100  # Maximum number of pixels in a region to be included

# Eccentricity of best fit ellipse goes from 0 to 1 - 0=Perfect Circle, 1 = Line.
minEccentricity = -0.1  # Use the Minimum to exclude round objects. Set below zero to allow all round objects
maxEccentricity = 1.1  # Use the Maximum to exclude long, thin objects. Set  above 1 to include all long, thin objects

minLength = 0  # Minimum length of the region
maxLength = 100000  # Maximum length of the region

maxDistFromLinear = 10000000  # Maximum distance that a pixel can deviate from the major axis.

# 5 - Expand Regions Parameters

foregroundDist = 4.1  # Distance to dilate the ROIs by to make sure all flourescence from the ROI is measured
backInnerDist = 4.1
backOuterDist = 20  # Distance to dilate beyond the ROI to measure the local background

# 6 - Calculate Traces Parameter
verboseOutput = False

# 7 - View Traces Parameter
pageNumber = 1

# 8 - Detect files for batch
filesInSubFolders = False

# 9 - Batch Analysis
overwritePreviouslyAnalysed = True


# ~~~~ Don't touch from here ~~~~ #
pyfile = sys.argv[0]
if _platform == "linux" or _platform == "linux2":
    JIM = os.path.dirname(os.path.dirname(pyfile)) + "/Jim_Programs_Linux/"
    fileSep = '/'
    fileEXE = ''
elif _platform == "darwin":
    JIM = os.path.dirname(os.path.dirname(pyfile)) + "/Jim_Programs_Mac/"
    fileSep = '/'
    fileEXE = ''
elif _platform == "win32" or _platform == "win64":
    JIM = os.path.dirname(os.path.dirname(pyfile)) + "\\Jim_Programs\\"
    fileEXE = '.exe'


#  Change if not running in original distribution folder e.g. JIM = "C:\\Users\\James\\Desktop\\Jim_v5\\Jim_Programs\\"

if sectionNumber != 1 and sectionNumber != 8:
    channelFile = os.path.dirname(pyfile) + fileSep + "saveFilename.csv"
    fileList = list(csv.reader(open(channelFile)))
    completeName = fileList[0][0]
    print("Analysing "+completeName)
    workingDir = os.path.dirname(completeName) + fileSep + str(os.path.basename(completeName).split(".", 1)[0]) + fileSep


# 1 - Select input file and create a folder for results
if sectionNumber == 1:
    root = tk.Tk()
    root.withdraw()

    completeName = filedialog.askopenfilename()
    completeName = completeName.replace("/", fileSep)
    completeName = completeName.replace("\\", fileSep)
    print(completeName)
    workingDir = os.path.dirname(completeName)+fileSep+str(os.path.basename(completeName).split(".", 1)[0])+fileSep
    print(workingDir)
    if not os.path.isdir(workingDir):
        os.makedirs(workingDir)
    savedFilenameFile = open(os.path.dirname(pyfile) + fileSep + "saveFilename.csv", "w")
    savedFilenameFile.write(completeName)
    savedFilenameFile.close()

# 2 - Drift Correct
if sectionNumber == 2:

    cmd = (JIM + 'Align_Channels' + fileEXE + ' \"' + workingDir + "Aligned\" \"" + completeName + "\" -Start "
           + str(alignStartFrame) + " -End " + str(alignEndFrame) + ' -Iterations '+str(iterations))
    os.system(cmd)

    imName = workingDir+"Aligned_initial_mean.tiff"
    img = mpimg.imread(imName)
    plt.figure('Before Drift Correction')
    plt.imshow(img, cmap="gray")

    imName = workingDir+"Aligned_final_mean.tiff"
    img = mpimg.imread(imName)
    plt.figure('After Drift Correction')
    plt.imshow(img, cmap="gray")
    plt.show()

# 3 - Make a SubAverage of the Image Stack for Detection
if sectionNumber == 3:

    maxProjectionString = ""
    if useMaxProjection:
        maxProjectionString = " -MaxProjection"

    cmd = (JIM + 'Mean_of_Frames' + fileEXE + ' NULL \"' + workingDir + "Aligned_Drifts.csv\" \""
           + workingDir + "Aligned\" \"" + completeName + "\" -Start " + str(detectionStartFrame)
           + " -End " + str(detectionEndFrame) + maxProjectionString)
    os.system(cmd)

    imName = workingDir+"Aligned_Partial_Mean.tiff"
    img = mpimg.imread(imName)
    plt.figure('Sub-Average to use for detection')
    imPlot = plt.imshow(img, cmap="gray")
    plt.show()


# 4 - detect particles
if sectionNumber == 4:

    cmd = (JIM + 'Detect_Particles' + fileEXE + ' \"' + workingDir + 'Aligned_Partial_Mean.tiff\" \"' + workingDir
           + 'Detected\" -BinarizeCutoff ' + str(cutoff) + ' -minLength ' + str(minLength) + ' -maxLength '
           + str(maxLength) + ' -minCount ' + str(minCount) + ' -maxCount ' + str(maxCount)
           + ' -minEccentricity ' + str(minEccentricity)+ ' -maxEccentricity ' + str(maxEccentricity)
           + ' -maxDistFromLinear ' + str(maxDistFromLinear)
           + ' -left ' + str(left) + ' -right ' + str(right) + ' -top ' + str(top) + ' -bottom ' + str(bottom))
    os.system(cmd)

    channel1Im = np.array(Image.open(workingDir+"Aligned_Partial_Mean.tiff")).astype(float)
    channel1Im = np.clip(255*(displayMax-displayMin)*(channel1Im - np.min(channel1Im)) / np.ptp(channel1Im)-displayMin, 0, 255)
    channel2Im = np.array(Image.open(workingDir + "Detected_Regions.tif"))
    channel3Im = np.array(Image.open(workingDir + "Detected_Filtered_Regions.tif"))
    combinedImage = (np.dstack((overlayColours1[0]*channel1Im + overlayColours2[0]*channel2Im + overlayColours3[0]*channel3Im,
                                overlayColours1[1]*channel1Im + overlayColours2[1]*channel2Im + overlayColours3[1]*channel3Im,
                                overlayColours1[2]*channel1Im + overlayColours2[2]*channel2Im + overlayColours3[2]*channel3Im))).astype(np.uint8)
    imPlot = plt.imshow(combinedImage)
    plt.show()


# 5 - Expand Regions
if sectionNumber == 5:
    cmd = (JIM + 'Expand_Shapes' + fileEXE + ' \"' + workingDir + 'Detected_Filtered_Positions.csv\" \"'
           + workingDir + 'Detected_Positions.csv\" \"' + workingDir + 'Expanded\" -boundaryDist '
           + str(foregroundDist) + ' -backgroundDist ' + str(backOuterDist) + ' -backInnerRadius '+str(backInnerDist))
    os.system(cmd)

    channel1Im = np.array(Image.open(workingDir+"Aligned_Partial_Mean.tiff")).astype(float)
    channel1Im = np.clip(255*(displayMax-displayMin)*(channel1Im - np.min(channel1Im)) / np.ptp(channel1Im)-displayMin, 0, 255)
    channel2Im = np.array(Image.open(workingDir + "Expanded_ROIs.tif"))
    channel3Im = np.array(Image.open(workingDir + "Expanded_Background_Regions.tif"))
    combinedImage = (np.dstack((overlayColours1[0]*channel1Im + overlayColours2[0]*channel2Im + overlayColours3[0]*channel3Im,
                                overlayColours1[1]*channel1Im + overlayColours2[1]*channel2Im + overlayColours3[1]*channel3Im,
                                overlayColours1[2]*channel1Im + overlayColours2[2]*channel2Im + overlayColours3[2]*channel3Im))).astype(np.uint8)
    imPlot = plt.imshow(combinedImage)
    plt.show()

# 6 - Calculate Traces
if sectionNumber == 6:
    verboseString = ''
    if verboseOutput:
        verboseString = ' -Verbose'

    cmd = (JIM + 'Calculate_Traces' + fileEXE + ' \"' + completeName + '\" \"' + workingDir + 'Expanded_ROI_Positions.csv\" \"'
           + workingDir + 'Expanded_Background_Positions.csv\" \"' + workingDir + 'Channel_1\" -Drift \"'
           + workingDir + 'Aligned_Drifts.csv\"'+verboseString)
    os.system(cmd)

    variableString = ('Date, ' + str(datetime.date.today()) + '\niterations,' + str(iterations) +
                      '\nalignStartFrame,' + str(alignStartFrame) + '\nalignEndFrame,' + str(alignEndFrame) +
                      '\nuseMaxProjection,' + str(int(useMaxProjection)) + '\ndetectionStartFrame,' + str(detectionStartFrame) +
                      '\ndetectionEndFrame,' + str(detectionEndFrame) + '\ncutoff,' + str(cutoff) +
                      '\nleft,' + str(left) + '\nright,' + str(right) + '\ntop,' + str(top) + '\nbottom,' + str(bottom) +
                      '\nminCount,' + str(minCount) + '\nmaxCount,' + str(maxCount) +
                      '\nminEccentricity,' +str(minEccentricity) + '\nmaxEccentricity,' + str(maxEccentricity) +
                      '\nminLength,' + str(minLength) + '\nmaxLength,' + str(maxLength) +
                      '\nmaxDistFromLinear,' + str(maxDistFromLinear) + '\nforegroundDist,' + str(foregroundDist) +
                      '\nbackInnerDist,' + str(backInnerDist) + '\nbackOuterDist,' + str(backOuterDist) +
                      '\nverboseOutput,' + str(int(verboseOutput)))

    saveVariablesFile = open(workingDir + "Trace_Generation_Variables.csv", "w")
    saveVariablesFile.write(variableString)
    saveVariablesFile.close()

# 7 - View Traces
if sectionNumber == 7:
    imName = workingDir + "Detected_Filtered_Region_Numbers.tif"
    img = mpimg.imread(imName)
    plt.figure('Before Drift Correction')
    imPlot = plt.imshow(img, cmap="gray")

    channelFile = workingDir+"Detected_Filtered_Measurements.csv"
    measurements = list(csv.reader(open(channelFile)))

    channelFile = workingDir+"Channel_1_Fluorescent_Intensities.csv"
    data = list(csv.reader(open(channelFile)))
    plt.figure(figsize=(13, 8))
    for i in range(1, 37):
        if len(data) > i+(pageNumber-1)*36:
            plt.subplot(6, 6, i)
            plt.plot([float(i) for i in data[i+(pageNumber-1)*36]])
            plt.plot(plt.xlim(), [0, 0], color='black')
            xpos = round(float(measurements[i+(pageNumber-1)*36][0]))
            ypos = round(float(measurements[i+(pageNumber-1)*36][1]))
            plt.title('Particle '+str(i+(pageNumber-1)*36)+' x '+str(xpos)+' y '+str(ypos))
    plt.tight_layout()
    plt.show()

# 8 - Detect files for batch
if sectionNumber == 8:
    root = tk.Tk()
    root.withdraw()
    topFolder = filedialog.askdirectory(parent=root)

    fileList = []
    if filesInSubFolders:
        for folder in os.listdir(topFolder):
            folderin = os.path.join(topFolder, folder)
            if os.path.isdir(folderin):
                for file in os.listdir(folderin):
                    if file.endswith(".tif") or file.endswith(".tiff") or file.endswith(".TIF") or file.endswith(".TIFF"):
                        fileList.append(os.path.join(folderin, file).replace("/", fileSep))
    else:
        for file in os.listdir(topFolder):
            if file.endswith(".tif") or file.endswith(".tiff") or file.endswith(".TIF") or file.endswith(".TIFF"):
                fileList.append(os.path.join(topFolder, file).replace("/", fileSep))

    print('There are ' + str(len(fileList))+' files to analyse')
    print(fileList)
    savedFilenameFile = open(os.path.dirname(pyfile) + fileSep + "saveFilename.csv", "w")
    for i in range(len(fileList)):
        savedFilenameFile.write(fileList[i]+"\n")
    savedFilenameFile.close()


if sectionNumber == 9:

    maxProjectionString = ""
    if useMaxProjection:
        maxProjectionString = " -MaxProjection"

    for filein in fileList:
        completeName = filein[0]
        print('Analysing file '+completeName)
        workingDir = os.path.dirname(completeName) + fileSep + str(os.path.basename(completeName).split(".", 1)[0]) + fileSep

        if os.path.isfile(workingDir + "Channel_1_Fluorescent_Intensities.csv"):
            print('Skipping ' + completeName + ' - Analysis already exists')
            continue

        if not os.path.isdir(workingDir):
            os.makedirs(workingDir)

        cmd = (JIM + 'Align_Channels' + fileEXE + ' \"' + workingDir + "Aligned\" \"" + completeName + "\" -Start "
               + str(alignStartFrame) + " -End " + str(alignEndFrame) + ' -Iterations ' + str(iterations))
        os.system(cmd)

        cmd = (JIM + 'Mean_of_Frames' + fileEXE + ' NULL \"' + workingDir + "Aligned_Drifts.csv\" \"" + workingDir + "Aligned\" \""
               + completeName + "\" -Start " + str(detectionStartFrame)
               + " -End " + str(detectionEndFrame) + maxProjectionString)
        os.system(cmd)

        cmd = (JIM + 'Detect_Particles' + fileEXE + ' \"' + workingDir + 'Aligned_Partial_Mean.tiff\" \"' + workingDir
               + 'Detected\" -BinarizeCutoff ' + str(cutoff) + ' -minLength ' + str(minLength) + ' -maxLength '
               + str(maxLength) + ' -minCount ' + str(minCount) + ' -maxCount ' + str(maxCount)
               + ' -minEccentricity ' + str(minEccentricity) + ' -maxEccentricity ' + str(maxEccentricity)
               + ' -maxDistFromLinear ' + str(maxDistFromLinear)
               + ' -left ' + str(left) + ' -right ' + str(right) + ' -top ' + str(top) + ' -bottom ' + str(bottom))
        os.system(cmd)

        cmd = (JIM + 'Expand_Shapes' + fileEXE + ' \"' + workingDir + 'Detected_Filtered_Positions.csv\" \"'
               + workingDir + 'Detected_Positions.csv\" \"' + workingDir + 'Expanded\" -boundaryDist '
               + str(foregroundDist) + ' -backgroundDist ' + str(backOuterDist) + ' -backInnerRadius ' + str(
                    backInnerDist))
        os.system(cmd)

        cmd = (JIM + 'Calculate_Traces' + fileEXE + ' \"' + completeName + '\" \"' + workingDir + 'Expanded_ROI_Positions.csv\" \"'
               + workingDir + 'Expanded_Background_Positions.csv\" \"' + workingDir + 'Channel_1\" -Drift \"'
               + workingDir + 'Aligned_Drifts.csv\"')
        os.system(cmd)

        variableString = ('Date, ' + str(datetime.date.today()) + '\niterations,' + str(iterations) +
                          '\nalignStartFrame,' + str(alignStartFrame) + '\nalignEndFrame,' + str(alignEndFrame) +
                          '\nuseMaxProjection,' + str(int(useMaxProjection)) + '\ndetectionStartFrame,' + str(detectionStartFrame) +
                          '\ndetectionEndFrame,' + str(detectionEndFrame) + '\ncutoff,' + str(cutoff) +
                          '\nleft,' + str(left) + '\nright,' + str(right) + '\ntop,' + str(top) + '\nbottom,' + str(bottom) +
                          '\nminCount,' + str(minCount) + '\nmaxCount,' + str(maxCount) +
                          '\nminEccentricity,' + str(minEccentricity) + '\nmaxEccentricity,' + str(maxEccentricity) +
                          '\nminLength,' + str(minLength) + '\nmaxLength,' + str(maxLength) +
                          '\nmaxDistFromLinear,' + str(maxDistFromLinear) + '\nforegroundDist,' + str(foregroundDist) +
                          '\nbackInnerDist,' + str(backInnerDist) + '\nbackOuterDist,' + str(backOuterDist) +
                          '\nverboseOutput,' + str(int(verboseOutput)))

        saveVariablesFile = open(workingDir + fileSep + "Trace_Generation_Variables.csv", "w")
        saveVariablesFile.write(variableString)
        saveVariablesFile.close()

    print('Batch Analysis Completed')
