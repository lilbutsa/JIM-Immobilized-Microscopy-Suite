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

sectionNumber = 10
# Sections
# 1 - Select input file and create a folder for results
# 2 - Split File into Individual Channels
# 3 - Invert Channel
# 4 - Align Channels and Calculate Drifts
# 5 - Make a SubAverage of Frames for Detection
# 6 - Detect Particles
# 7 - Calculate Regions for Other Channels
# 8 - Expand Regions
# 9 - Calculate Traces
# 10 - View Traces
# 11 - Detect files for batch
# 12 - Batch Analyse

# ~~~~PARAMETER INPUTS~~~~ #

# General Display Parameters

overlayColours1 = [1, 0, 0]
overlayColours2 = [0, 1, 0]
overlayColours3 = [0, 0, 1]

displayMin = 1
displayMax = 3

# 2 - Split File into Individual Channels Parameters
useMetadataFile = False
numberOfChannels = 2

# 3 - Invert Channel Parameters
invertChannel = False
channelToInvert = 2

# 4 - Align Channels and Calculate Drifts Parameters
iterations = 1
alignStartFrame = 15
alignEndFrame = 15

manualAlignment = False
rotationAngle = -2.86
scalingFactor = 1
xoffset = -5
yoffset = -5

# 5 - Make a SubAverage of the Image Stack for Detection Parameters
useMaxProjection = False
detectionStartFrame = '1 20'
detectionEndFrame = '10 30'

# 6 - Detect Particles Parameters
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
maxLength = 10000000  # Maximum length of the region

maxDistFromLinear = 10000000  # Maximum distance that a pixel can deviate from the major axis.

# 8 - Expand Regions Parameters

foregroundDist = 4.1  # Distance to dilate the ROIs by to make sure all flourescence from the ROI is measured
backInnerDist = 4.1
backOuterDist = 20  # Distance to dilate beyond the ROI to measure the local background

# 9 - Calculate Traces Parameter
verboseOutput = False

# 10 - View Traces Parameter
pageNumber = 1

# 11 - Detect files for batch
filesInSubFolders = False

# 12 - Batch Analysis
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
    fileEXE = '' + fileEXE + ''
#  Change if not running in original distribution folder e.g. JIM = "C:\\Users\\James\\Desktop\\Jim_v5\\Jim_Programs\\"

if sectionNumber != 1 and sectionNumber != 11:
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

# 2 - Split File into Individual Channels Parameters
if sectionNumber == 2:
    if useMetadataFile:
        metaFileName = (os.path.dirname(completename) + fileSep
                        + str(os.path.basename(completename).split(".", 1)[0]) + '_metadata.txt')
        cmd = (JIM + 'TIFF_Channel_Splitter' + fileEXE + ' \"' + completeName + '\" \"' + workingDir
               + 'Images\" -MetadataFile \"' + metaFileName + '\"')
    else:
        cmd = (
                    JIM + 'TIFF_Channel_Splitter' + fileEXE + ' \"' + completeName + '\" \"' + workingDir + 'Images\" -NumberOfChannels '
                    + str(numberOfChannels))
    os.system(cmd)

# 3 - Invert Second Channel
if sectionNumber == 3 and invertChannel:
    cmd = (JIM + 'Invert_Channel' + fileEXE + ' "' + workingDir + 'Images_Channel_' + channelToInvert + '.tiff" "' + workingDir +
           'Images_Channel_' + channelToInvert + '_Inverted.tiff"')
    system(cmd)
    os.remove(workingDir + 'Images_Channel_' + channelToInvert + '.tiff')
    os.rename(workingDir + 'Images_Channel_' + channelToInvert + '_Inverted.tiff', workingDir + 'Images_Channel_' + channelToInvert + '.tiff')

# 4 - Align Channels and Calculate Drifts
if sectionNumber == 4:
    allChannelNames = ''  # the string list of all channel names
    for j in range(numberOfChannels):
        allChannelNames += ' "' + workingDir + 'Images_Channel_' + str(j + 1) + '.tiff"'

    if manualAlignment:
        cmd = (JIM + 'Align_Channels' + fileEXE + ' \"' + workingDir + "Aligned\"" + allChannelNames + " -Start "
               + str(alignStartFrame) + " -End " + str(alignEndFrame) + ' -Iterations ' + str(iterations) +
               ' -Alignment ' + str(xoffset) + ' ' + str(yoffset) + ' ' + str(rotationAngle) + ' ' + str(scalingFactor))

    else:
        cmd = (JIM + 'Align_Channels' + fileEXE + ' \"' + workingDir + "Aligned\"" + allChannelNames + " -Start "
               + str(alignStartFrame) + " -End " + str(alignEndFrame) + ' -Iterations ' + str(iterations))
    os.system(cmd)

    if manualAlignment:
        channel1Im = np.array(Image.open(workingDir + "Aligned_aligned_partial_mean_1.tiff")).astype(float)
        channel2Im = np.array(Image.open(workingDir + "Aligned_aligned_partial_mean_2.tiff")).astype(float)
    else:
        channel1Im = np.array(Image.open(workingDir + "Aligned_initial_partial_mean_1.tiff")).astype(float)
        channel2Im = np.array(Image.open(workingDir + "Aligned_initial_partial_mean_2.tiff")).astype(float)

    channel1Im = np.clip(
        255 * (displayMax - displayMin) * (channel1Im - np.min(channel1Im)) / np.ptp(channel1Im) - displayMin, 0, 255)
    channel2Im = np.clip(
        255 * (displayMax - displayMin) * (channel2Im - np.min(channel2Im)) / np.ptp(channel2Im) - displayMin, 0, 255)

    combinedImage = (np.dstack((overlayColours1[0] * channel1Im + overlayColours2[0] * channel2Im,
                                overlayColours1[1] * channel1Im + overlayColours2[1] * channel2Im,
                                overlayColours1[2] * channel1Im + overlayColours2[2] * channel2Im))).astype(np.uint8)
    plt.figure('Before Drift Correction and Alignment')
    plt.imshow(combinedImage)

    channel1Im = np.array(Image.open(workingDir + "Aligned_aligned_full_mean_1.tiff")).astype(float)
    channel2Im = np.array(Image.open(workingDir + "Aligned_aligned_full_mean_2.tiff")).astype(float)
    channel1Im = np.clip(
        255 * (displayMax - displayMin) * (channel1Im - np.min(channel1Im)) / np.ptp(channel1Im) - displayMin, 0, 255)
    channel2Im = np.clip(
        255 * (displayMax - displayMin) * (channel2Im - np.min(channel2Im)) / np.ptp(channel2Im) - displayMin, 0, 255)

    combinedImage = (np.dstack((overlayColours1[0] * channel1Im + overlayColours2[0] * channel2Im,
                                overlayColours1[1] * channel1Im + overlayColours2[1] * channel2Im,
                                overlayColours1[2] * channel1Im + overlayColours2[2] * channel2Im))).astype(np.uint8)
    plt.figure('After Drift Correction and Alignment')
    plt.imshow(combinedImage)

    plt.show()

# 5 - Make a SubAverage of the Image Stack for Detection
if sectionNumber == 5:
    allChannelNames = ''  # the string list of all channel names
    for j in range(numberOfChannels):
        allChannelNames += ' "' + workingDir + 'Images_Channel_' + str(j + 1) + '.tiff"'

    maxProjectionString = ""
    if useMaxProjection:
        maxProjectionString = " -MaxProjection"

    cmd = (
                JIM + 'Mean_of_Frames' + fileEXE + ' \"' + workingDir + 'Aligned_channel_alignment.csv\" \"' + workingDir + "Aligned_Drifts.csv\" \"" + workingDir + "Aligned\""
                + allChannelNames + " -Start " + detectionStartFrame + " -End " + detectionEndFrame + maxProjectionString)
    os.system(cmd)

    imName = workingDir + "Aligned_Partial_Mean.tiff"
    img = mpimg.imread(imName)
    plt.figure('Sub-Average to use for detection')
    plt.imshow(img, cmap="gray")
    plt.show()

# 6 - detect particles
if sectionNumber == 6:
    cmd = (JIM + 'Detect_Particles' + fileEXE + ' \"' + workingDir + 'Aligned_Partial_Mean.tiff\" \"' + workingDir
           + 'Detected\" -BinarizeCutoff ' + str(cutoff) + ' -minLength ' + str(minLength) + ' -maxLength '
           + str(maxLength) + ' -minCount ' + str(minCount) + ' -maxCount ' + str(maxCount)
           + ' -minEccentricity ' + str(minEccentricity)
           + ' -maxEccentricity ' + str(maxEccentricity) + ' -maxDistFromLinear ' + str(maxDistFromLinear)
           + ' -left ' + str(left) + ' -right ' + str(right) + ' -top ' + str(top) + ' -bottom ' + str(bottom))
    os.system(cmd)

    channel1Im = np.array(Image.open(workingDir + "Aligned_Partial_Mean.tiff")).astype(float)
    channel1Im = np.clip(
        255 * (displayMax - displayMin) * (channel1Im - np.min(channel1Im)) / np.ptp(channel1Im) - displayMin, 0, 255)
    channel2Im = np.array(Image.open(workingDir + "Detected_Regions.tif"))
    channel3Im = np.array(Image.open(workingDir + "Detected_Filtered_Regions.tif"))
    combinedImage = (
        np.dstack((overlayColours1[0] * channel1Im + overlayColours2[0] * channel2Im + overlayColours3[0] * channel3Im,
                   overlayColours1[1] * channel1Im + overlayColours2[1] * channel2Im + overlayColours3[1] * channel3Im,
                   overlayColours1[2] * channel1Im + overlayColours2[2] * channel2Im + overlayColours3[
                       2] * channel3Im))).astype(np.uint8)
    plt.figure(
        'Detected Particles - Red Original Image - Blue to White Selected ROIs - Green to Yellow->Excluded by filters')
    plt.imshow(combinedImage)
    plt.show()

# 7 - Calculate Regions for Other Channels
if sectionNumber == 7:
    cmd = (JIM + 'Other_Channel_Positions' + fileEXE + ' "' + workingDir + 'Aligned_channel_alignment.csv" "' + workingDir +
           'Aligned_Drifts.csv" "' + workingDir + 'Detected_Filtered_Measurements.csv" "' + workingDir +
           'Detected_Filtered" -positions "' + workingDir + 'Detected_Filtered_Positions.csv" -backgroundpositions "' +
           workingDir + 'Detected_Positions.csv"')
    os.system(cmd)

# 8 - Expand Regions
if sectionNumber == 8:
    cmd = (JIM + 'Expand_Shapes' + fileEXE + ' "' + workingDir + 'Detected_Filtered_Positions.csv" "' + workingDir +
           'Detected_Positions.csv" "' + workingDir + 'Expanded_Channel_1" -boundaryDist ' + str(foregroundDist) +
           ' -backgroundDist ' + str(backOuterDist) + ' -backInnerRadius ' + str(backInnerDist))
    os.system(cmd)

    for j in range(2, numberOfChannels + 1):
        cmd = (JIM + 'Expand_Shapes' + fileEXE + ' "' + workingDir + 'Detected_Filtered_Positions_Channel_' + str(j) + '.csv" "' +
               workingDir + 'Detected_Filtered_Background_Positions_Channel_' + str(j) + '.csv" "' + workingDir +
               'Expanded_Channel_' + str(j) + '" -boundaryDist ' + str(foregroundDist) + ' -backgroundDist ' +
               str(backOuterDist) + ' -backInnerRadius ' + str(backInnerDist))
        os.system(cmd)

    for j in range(1, numberOfChannels + 1):
        if j == 1:
            channel1Im = np.array(Image.open(workingDir + 'Aligned_aligned_full_mean_1.tiff')).astype(float)
        else:
            channel1Im = np.array(Image.open(workingDir + 'Aligned_initial_full_mean_' + str(j) + '.tiff')).astype(
                float)
        channel1Im = np.clip(
            255 * (displayMax - displayMin) * (channel1Im - np.min(channel1Im)) / np.ptp(channel1Im) - displayMin, 0,
            255)
        channel2Im = np.array(Image.open(workingDir + 'Expanded_Channel_' + str(j) + '_ROIs.tif'))
        channel3Im = np.array(Image.open(workingDir + 'Expanded_Channel_' + str(j) + '_Background_Regions.tif'))
        combinedImage = (np.dstack(
            (overlayColours1[0] * channel1Im + overlayColours2[0] * channel2Im + overlayColours3[0] * channel3Im,
             overlayColours1[1] * channel1Im + overlayColours2[1] * channel2Im + overlayColours3[1] * channel3Im,
             overlayColours1[2] * channel1Im + overlayColours2[2] * channel2Im + overlayColours3[
                 2] * channel3Im))).astype(np.uint8)
        plt.figure(
            'Channel ' + str(j) + ' Detected Particles - Red Original Image - Green ROIs - Blue Background Regions')
        plt.imshow(combinedImage)

    plt.show()

# 9 - Calculate Traces
if sectionNumber == 9:

    verboseString = ''
    if verboseOutput:
        verboseString = ' -Verbose'

    cmd = (JIM + 'Calculate_Traces' + fileEXE + ' \"' + workingDir + 'Images_Channel_1.tiff\" \"'
           + workingDir + 'Expanded_Channel_1_ROI_Positions.csv\" \"'
           + workingDir + 'Expanded_Channel_1_Background_Positions.csv\" \"' + workingDir + 'Channel_1\" -Drift \"'
           + workingDir + 'Aligned_Drifts.csv\"' + verboseString)
    os.system(cmd)

    for j in range(2, numberOfChannels + 1):
        cmd = (JIM + 'Calculate_Traces' + fileEXE + ' \"' + workingDir + 'Images_Channel_' + str(j) + '.tiff\" \"'
               + workingDir + 'Expanded_Channel_' + str(j) + '_ROI_Positions.csv\" \"'
               + workingDir + 'Expanded_Channel_' + str(j) + '_Background_Positions.csv\" \"'
               + workingDir + 'Channel_' + str(j) + '\" -Drift \"'
               + workingDir + 'Detected_Filtered_Drifts_Channel_' + str(j) + '.csv\"' + verboseString)
        os.system(cmd)

    variableString = ('Date, ' + str(datetime.date.today()) +
                      '\nuseMetadataFile,' + str(int(useMetadataFile)) + '\nnumberOfChannels,' + str(numberOfChannels) +
                      '\ninvertChannel,' + str(int(invertChannel)) + '\nchannelToInvert,' + str(channelToInvert) +
                      '\niterations,' + str(iterations) +
                      '\nalignStartFrame,' + str(alignStartFrame) + '\nalignEndFrame,' + str(alignEndFrame) +
                      '\nmanualAlignment,' + str(int(manualAlignment)) +
                      '\nrotationAngle,' + str(rotationAngle) + '\nscalingFactor,' + str(scalingFactor) +
                      '\nxoffset,' + str(xoffset) + '\nyoffset,' + str(yoffset) +
                      '\nuseMaxProjection,' + str(int(useMaxProjection)) + '\ndetectionStartFrame,' + detectionStartFrame +
                      '\ndetectionEndFrame,' + detectionEndFrame + '\ncutoff,' + str(cutoff) +
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

# 10 - View Traces
if sectionNumber == 10:
    imName = workingDir + "Detected_Filtered_Region_Numbers.tif"
    img = mpimg.imread(imName)
    plt.figure('Before Drift Correction')
    imPlot = plt.imshow(img, cmap="gray")

    channelFile = workingDir + "Detected_Filtered_Measurements.csv"
    measurements = list(csv.reader(open(channelFile)))

    channelFile = workingDir + "Channel_1_Fluorescent_Intensities.csv"
    data = list(csv.reader(open(channelFile)))
    channelFile = workingDir + "Channel_2_Fluorescent_Intensities.csv"
    data2 = list(csv.reader(open(channelFile)))
    plt.figure(figsize=(13, 8))
    for i in range(1, 37):
        if len(data) > i + (pageNumber - 1) * 36:
            plt.subplot(6, 6, i)
            myMax = max(map(float, data[i + (pageNumber - 1) * 36]))
            list2 = map(float, data[i + (pageNumber - 1) * 36])
            plt.plot([x / myMax for x in map(float, data[i + (pageNumber - 1) * 36])], color='red')
            myMax = max(map(float, data2[i + (pageNumber - 1) * 36]))
            plt.plot([x / myMax for x in map(float, data2[i + (pageNumber - 1) * 36])], color='blue')
            plt.plot(plt.xlim(), [0, 0], color='black')
            xpos = round(float(measurements[i + (pageNumber - 1) * 36][0]))
            ypos = round(float(measurements[i + (pageNumber - 1) * 36][1]))
            plt.title('Particle ' + str(i + (pageNumber - 1) * 36) + ' x ' + str(xpos) + ' y ' + str(ypos))
    plt.tight_layout()
    plt.show()

# 11 - Detect files for batch
if sectionNumber == 11:
    root = tk.Tk()
    root.withdraw()
    topFolder = filedialog.askdirectory(parent=root)

    fileList = []
    if filesInSubFolders:
        for folder in os.listdir(topFolder):
            folderin = os.path.join(topFolder, folder)
            if os.path.isdir(folderin):
                for file in os.listdir(folderin):
                    if file.endswith(".tif") or file.endswith(".tiff") or file.endswith(".TIF") or file.endswith(
                            ".TIFF"):
                        fileList.append(os.path.join(folderin, file).replace("/", fileSep))
    else:
        for file in os.listdir(topFolder):
            if file.endswith(".tif") or file.endswith(".tiff") or file.endswith(".TIF") or file.endswith(".TIFF"):
                fileList.append(os.path.join(topFolder, file).replace("/", fileSep))

    print('There are ' + str(len(fileList)) + ' files to analyse')
    print(fileList)
    savedFilenameFile = open(os.path.dirname(pyfile) + fileSep + "saveFilename.csv", "w")
    for i in range(len(fileList)):
        savedFilenameFile.write(fileList[i] + "\n")
    savedFilenameFile.close()

# 12 - Batch Analysis

if sectionNumber == 12:

    maxProjectionString = ""
    if useMaxProjection:
        maxProjectionString = " -MaxProjection"

    verboseString = ''
    if verboseOutput:
        verboseString = ' -Verbose'

    for filein in fileList:
        completeName = filein[0]
        print('Analysing file '+completeName)
        workingDir = os.path.dirname(completeName) + fileSep + str(os.path.basename(completeName).split(".", 1)[0]) + fileSep
        if os.path.isfile(workingDir + "Channel_1_Fluorescent_Intensities.csv"):
            print('Skipping '+ completeName + ' - Analysis already exists')
            continue

        if not os.path.isdir(workingDir):
            os.makedirs(workingDir)

        # 2 - Split File into Individual Channels Parameters

        if useMetadataFile:
            metaFileName = (os.path.dirname(completename) + fileSep
                            + str(os.path.basename(completename).split(".", 1)[0]) + '_metadata.txt')
            cmd = (JIM + 'TIFF_Channel_Splitter' + fileEXE + ' \"' + completeName + '\" \"' + workingDir
                   + 'Images\" -MetadataFile \"' + metaFileName + '\"')
        else:
            cmd = (
                    JIM + 'TIFF_Channel_Splitter' + fileEXE + ' \"' + completeName + '\" \"' + workingDir + 'Images\" -NumberOfChannels '
                    + str(numberOfChannels))
        os.system(cmd)

        # 3 - Invert Second Channel
        if invertChannel:
            cmd = (JIM + 'Invert_Channel' + fileEXE + ' "' + workingDir + 'Images_Channel_2.tiff" "' + workingDir +
                   'Images_Channel_2_Inverted.tiff"')
            system(cmd)
            os.remove(workingDir + 'Images_Channel_2.tiff')
            os.rename(workingDir + 'Images_Channel_2_Inverted.tiff', workingDir + 'Images_Channel_2.tiff')

        # 4 - Align Channels and Calculate Drifts

        allChannelNames = ''  # the string list of all channel names
        for j in range(numberOfChannels):
            allChannelNames += ' "' + workingDir + 'Images_Channel_' + str(j + 1) + '.tiff"'

        if manualAlignment:
            cmd = (JIM + 'Align_Channels' + fileEXE + ' \"' + workingDir + "Aligned\"" + allChannelNames + " -Start "
                   + str(alignStartFrame) + " -End " + str(alignEndFrame) + ' -Iterations ' + str(iterations) +
                   ' -Alignment ' + str(xoffset) + ' ' + str(yoffset) + ' ' + str(rotationAngle) + ' ' + str(
                        scalingFactor))

        else:
            cmd = (JIM + 'Align_Channels' + fileEXE + ' \"' + workingDir + "Aligned\"" + allChannelNames + " -Start "
                   + str(alignStartFrame) + " -End " + str(alignEndFrame) + ' -Iterations ' + str(iterations))
        os.system(cmd)

        # 5 - Make a SubAverage of the Image Stack for Detection

        maxProjectionString = ""
        if useMaxProjection:
            maxProjectionString = " -MaxProjection"

        cmd = (
                JIM + 'Mean_of_Frames' + fileEXE + ' \"' + workingDir + 'Aligned_channel_alignment.csv\" \"' + workingDir + "Aligned_Drifts.csv\" \"" + workingDir + "Aligned\""
                + allChannelNames + " -Start " + detectionStartFrame + " -End " + detectionEndFrame + maxProjectionString)
        os.system(cmd)

        # 6 - detect particles

        cmd = (JIM + 'Detect_Particles' + fileEXE + ' \"' + workingDir + 'Aligned_Partial_Mean.tiff\" \"' + workingDir
               + 'Detected\" -BinarizeCutoff ' + str(cutoff) + ' -minLength ' + str(minLength) + ' -maxLength '
               + str(maxLength) + ' -minCount ' + str(minCount) + ' -maxCount ' + str(maxCount)
               + ' -minEccentricity ' + str(minEccentricity)
               + ' -maxEccentricity ' + str(maxEccentricity) + ' -maxDistFromLinear ' + str(maxDistFromLinear)
               + ' -left ' + str(left) + ' -right ' + str(right) + ' -top ' + str(top) + ' -bottom ' + str(bottom))
        os.system(cmd)

        # 7 - Calculate Regions for Other Channels

        cmd = (JIM + 'Other_Channel_Positions' + fileEXE + ' "' + workingDir + 'Aligned_channel_alignment.csv" "' + workingDir +
               'Aligned_Drifts.csv" "' + workingDir + 'Detected_Filtered_Measurements.csv" "' + workingDir +
               'Detected_Filtered" -positions "' + workingDir + 'Detected_Filtered_Positions.csv" -backgroundpositions "' +
               workingDir + 'Detected_Positions.csv"')
        os.system(cmd)

        # 8 - Expand Regions
        cmd = (JIM + 'Expand_Shapes' + fileEXE + ' "' + workingDir + 'Detected_Filtered_Positions.csv" "' + workingDir +
               'Detected_Positions.csv" "' + workingDir + 'Expanded_Channel_1" -boundaryDist ' + str(foregroundDist) +
               ' -backgroundDist ' + str(backOuterDist) + ' -backInnerRadius ' + str(backInnerDist))
        os.system(cmd)

        for j in range(2, numberOfChannels + 1):
            cmd = (JIM + 'Expand_Shapes' + fileEXE + ' "' + workingDir + 'Detected_Filtered_Positions_Channel_' + str(
                j) + '.csv" "' +
                   workingDir + 'Detected_Filtered_Background_Positions_Channel_' + str(j) + '.csv" "' + workingDir +
                   'Expanded_Channel_' + str(j) + '" -boundaryDist ' + str(foregroundDist) + ' -backgroundDist ' +
                   str(backOuterDist) + ' -backInnerRadius ' + str(backInnerDist))
            os.system(cmd)

        # 9 - Calculate Traces

        cmd = (JIM + 'Calculate_Traces' + fileEXE + ' \"' + workingDir + 'Images_Channel_1.tiff\" \"'
               + workingDir + 'Expanded_Channel_1_ROI_Positions.csv\" \"'
               + workingDir + 'Expanded_Channel_1_Background_Positions.csv\" \"' + workingDir + 'Channel_1\" -Drift \"'
               + workingDir + 'Aligned_Drifts.csv\"' + verboseString)
        os.system(cmd)

        for j in range(2, numberOfChannels + 1):
            cmd = (JIM + 'Calculate_Traces' + fileEXE + ' \"' + workingDir + 'Images_Channel_' + str(j) + '.tiff\" \"'
                   + workingDir + 'Expanded_Channel_' + str(j) + '_ROI_Positions.csv\" \"'
                   + workingDir + 'Expanded_Channel_' + str(j) + '_Background_Positions.csv\" \"'
                   + workingDir + 'Channel_' + str(j) + '\" -Drift \"'
                   + workingDir + 'Detected_Filtered_Drifts_Channel_' + str(j) + '.csv\"' + verboseString)
            os.system(cmd)

        variableString = ('Date, ' + str(datetime.date.today()) +
                          '\nuseMetadataFile,' + str(int(useMetadataFile)) + '\nnumberOfChannels,' + str(
                    numberOfChannels) +
                          '\ninvertChannel,' + str(int(invertChannel)) + '\nchannelToInvert,' + str(channelToInvert) +
                          '\niterations,' + str(iterations) +
                          '\nalignStartFrame,' + str(alignStartFrame) + '\nalignEndFrame,' + str(alignEndFrame) +
                          '\nmanualAlignment,' + str(int(manualAlignment)) +
                          '\nrotationAngle,' + str(rotationAngle) + '\nscalingFactor,' + str(scalingFactor) +
                          '\nxoffset,' + str(xoffset) + '\nyoffset,' + str(yoffset) +
                          '\nuseMaxProjection,' + str(int(useMaxProjection)) + '\ndetectionStartFrame,' + detectionStartFrame +
                          '\ndetectionEndFrame,' + detectionEndFrame + '\ncutoff,' + str(cutoff) +
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


