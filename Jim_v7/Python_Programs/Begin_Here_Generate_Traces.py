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
from multiprocessing import Pool

sectionNumber = 10
# Sections

# 0 - Import Parameters
# 1 - Select input file and create a folder for results
# 2 - Split File into Individual Channels
# 3 - Align Channels and Calculate Drifts
# 4 - Make a SubAverage of the Image Stack for Detection
# 5 - Detect Particles
# 6 - Additional Background Detection
# 7 - Expand Regions
# 8 - Calculate Traces
# 9 - View Traces
# 10 - Extract Trace
# 11 - Detect files for batch
# 12 - Batch Analyse
# 13 - Export All Batch Traces

# ~~~~PARAMETER INPUTS~~~~ #

# General Display Parameters

# Change the overlay colours for colourblind as desired. In RGB, values from 0 to 1. Make sure there are at least one colour for each channel
overlayColours = [[1, 0, 0], [0, 1, 0], [0, 0, 1]]

# This just adjusts the contrast in the displayed image. It does NOT effect detection
displayMin = 0
displayMax = 95

# 1 - Select Input File
additionalExtensionsToRemove = 0  # remove extra .ome from working folder name if you want to

# 2 - Split File into Individual Channels Parameters
imStackMultipleFiles = False   # choose this if you're stack is split over multiple tiff files (i.e. >4Gb)
imStackNumberOfChannels = 1  # Input the number of channels in the data

imStackDisableMetadata = True   # Images are usually split using embedded OME metadata but can be disabled if this causes problems

imStackStartFrame = 1  # Part of the image stack can be completely ignored for all downstream analysis, set to 1 to start from the first frame
imStackEndFrame = -1  # Last frame to take. Negative numbers go from the end of the stack, so set to -1 to take the entire stack.

imStackChannelsToTransform = ''  # If no channels need to be transformed set channelsToTransform 
imStackVerticalFlipChannel = '1'  # For each channel to be transformed put 1 to flip that channel or 0 to not. eg. '1 0' to flip channel 2 but not 3.
imStackHorizontalFlipChannel = '0'  # Same as vertical
imStackRotateChannel = '0'  # Rotate should either be 0, 90, 180 or 270 for the angle to rotate each selected channel

# 3 - Align Channels and Calculate Drifts Parameters
alignIterations = 1  # Number of times to iterate drift correction calculations - 1 is fine if there minimal drift in the reference frames

alignStartFrame = 1  # Select reference frames where there is signal in all channels at the same time start frame from 1
alignEndFrame = 5

alignMaxShift = 10.00  # Limit the mamximum distance that the program will shift images for alignment this can help stop false alignments

# Output the aligned image stacks. Note this is not required by JIM but can
# be helpful for visualization. To save space, aligned stack will not output in batch
# regarless of this value
alignOutputStacks = False 

# Parmeters for Automatic Alignment
alignMaxIntensities = '65000 65000'  # Set a threshold so that during channel to channel alignment agregates are ignored
alignSNRCutoff = 1.00  # Set a minimum alignment SNR to throw warnings

# Multi Channel Alignment
alignManually = False   # Manually set the alignment between the multiple channels, If set to false the program will try to automatically find an alignment
alignXOffset = '0'
alignYOffset = '0'
alignRotationAngle = '0'
alignScalingFactor = '1'

# 4 - Make a SubAverage of the Image Stack for Detection Parameters
detectUsingMaxProjection = False   # Use a max projection rather than mean. This is better for short lived blinking particles

detectionStartFrame = '1'  # first frame of the reference region for detection for each channel
detectionEndFrame = '25'  # last frame of reference region. Negative numbers go from end of stack. i.e. -1 is last image in stack
detectWeights = '1'  # Each channel is multiplied by this value before they're combined. This is handy if one channel is much brigthter than another.

# 5 - Detect Particles Parameters
# Thresholding
detectionCutoff = 0.60  # The cutoff for the initial thresholding. Typically in range 0.25-2

# Filtering
detectLeftEdge = 10  # Excluded particles closer to the left edge than this. Make sure this value is larger than the maximum drift. 25 works well in most cases
detectRightEdge = 10  # Excluded particles closer to the Right edge than this.
detectTopEdge = 10  # Excluded particles closer to the Top edge than this.
detectBottomEdge = 10  # Excluded particles closer to the Bottom edge than this.

detectMinCount = 10  # Minimum number of pixels in a ROI to be counted as a particle. Use this to exclude speckles of background
detectMaxCount = 100  # Maximum number of pixels in a ROI to be counted as a particle. Use this to exclude aggregates

detectMinEccentricity = -0.10  # Eccentricity of best fit ellipse goes from 0 to 1 - 0
detectMaxEccentricity = 1.10  # Use the maximum to exclude long, thin objects. Set it to a value above 1 to include long, thin objects

detectMinLength = 0.00  # Minimum number of pixels for the major axis of the best fit ellipse
detectMaxLength = 10000.00  # Maximum number of pixels for the major axis of the best fit ellipse

detectMaxDistFromLinear = 10000.00  # Maximum distance that a pixel can diviate from the major axis.

detectMinSeparation = -1000.00  # Minimum separation between ROI's. Given by the closest edge between particles Set to 0 to accept all particles

# 6 - Additional Background Detection Subaverage - Use this to detect all other particles that are not in the detection image to cut around for background

additionBackgroundDetect = False   # enable the additional detection. Disable if all particles were detected (before filtering) above.

additionBackgroundUseMaxProjection = True   # Use a max projection rather than mean. This is better for short lived blinking particles

additionalBackgroundStartFrame = '1 1'  # first frame of the reference region for background detection
additionalBackgroundEndFrame = '-1 -1'  # last frame of background reference region. Negative numbers go from end of stack. i.e. -1 is last image in stack

additionalBackgroundWeights = '1 1'

additionBackgroundCutoff = 1.00  # Threshold for particles to be detected for background

# 7 - Expand Regions Parameters

expandForegroundDist = 4.10  # Distance to dilate the ROIs by to make sure all flourescence from the ROI is measured
expandBackInnerDist = 4.10  # Minimum distance to dilate beyond the ROI to measure the local background
expandBackOuterDist = 20.00  # Maximum distance to dilate beyond the ROI to measure the local background

# 8 - Calculate Traces Parameter
traceVerboseOutput = False   # Create additional file with additional statistics on each particle in each frame. Warning, this file can get very large. In general you don't want this.

# 9 - View Traces Parameter
montagePageNumber = 1  # Select the page number for traces. 28 traces per page. So traces from(n-1)*28+1 to n*28
montageTimePerFrame = 1 # Set to zero to just have frames
montageTimeUnits = 'Frames'  # Unit to use for x axis

# 10 - Extract Trace
montageTraceNo = 80
montageStart = 3
montageEnd = 48
montageDelta = 5
montageAverage = 5

montageOutputParticleImageStack = False  # Create a Tiff stack of the ROI of the particle

# BATCH DETECTION SETTINGS

# 11 - Detect files for batch
filesInSubFolders = False

# 12 - Batch Analysis
overwritePreviouslyAnalysed = True
deleteWorkingImageStacks = True

batchNumberOfThreads = 5

# ~~~~ Don't touch from here ~~~~ #

pyfile = sys.argv[0]
fileSep = '\\'
JIM = ''
fileEXE = str('')
workingDir = ''
completeName = ''
if _platform == "linux" or _platform == "linux2":
    JIM = os.path.dirname(os.path.dirname(pyfile)) + "/c++_Base_Programs/Linux/"
    fileSep = '/'
elif _platform == "darwin":
    JIM = os.path.dirname(os.path.dirname(pyfile)) + "/c++_Base_Programs/Mac/"
    fileSep = '/'
elif _platform == "win32" or _platform == "win64":
    JIM = os.path.dirname(os.path.dirname(pyfile)) + "\\c++_Base_Programs\\Windows\\"
    fileEXE = '.exe'
#  Change if not running in original distribution folder e.g. JIM = "C:\\Users\\James\\Desktop\\Jim_v#\\Jim_Programs\\"

# 0 - Import Parameters
if sectionNumber == 0:
    root = tk.Tk()
    root.withdraw()

    completeName = filedialog.askopenfilename()
    parameterList = list(csv.reader(open(completeName)))
    parameterList.pop(0)

    my_file = open(pyfile, "r")
    data = my_file.read()
    my_file.close()
    programFileList = data.split('\n')

    paramIsString = [6, 7, 8, 9, 15, 18, 19, 20, 21, 23, 24, 25, 41, 42, 43]
    paramIndex = 0
    for paramIn in parameterList:
        index = [idx for idx, s in enumerate(programFileList) if paramIn[0] in s]
        if len(index) == 0:
            print(paramIn)
            break

        if len(paramIn) == 1:
            paramVal = ''
        else:
            paramVal = paramIn[1]

        paramVal = paramVal.replace('true', 'True')
        paramVal = paramVal.replace('false', 'False')
        if paramIndex in paramIsString:
            stringOut = paramIn[0] + ' = \'' + paramVal + '\''
        else:
            stringOut = paramIn[0] + ' = ' + paramVal

        splitLine = programFileList[index[0]].split('=')
        splitLine = splitLine[1].split('#', 1)
        if len(splitLine) > 1:
            stringOut = stringOut + '  #' + splitLine[1]
        #print(stringOut)

        programFileList[index[0]] = stringOut

        paramIndex = paramIndex + 1

    with open(pyfile, 'w') as f:
        for line in programFileList:
            f.write("%s\n" % line)

# 1 - Select input file and create a folder for results
if sectionNumber == 1:
    root = tk.Tk()
    root.withdraw()

    completeName = filedialog.askopenfilename()
    completeName = completeName.replace("/", fileSep)
    completeName = completeName.replace("\\", fileSep)

    print(completeName)
    baseName = os.path.basename(completeName)
    splitBaseName = baseName.split(".")
    baseNameOut = splitBaseName[0]
    for x in range(1, len(splitBaseName) - additionalExtensionsToRemove - 1):
        baseNameOut = baseNameOut + "." + splitBaseName[x]
    workingDir = os.path.dirname(completeName) + fileSep + baseNameOut + fileSep

    if not os.path.isdir(workingDir):
        os.makedirs(workingDir)

    savedFilenameFile = open(os.path.dirname(pyfile) + fileSep + "saveFilename.csv", "w")
    savedFilenameFile.write(completeName + ',' + workingDir)
    savedFilenameFile.close()

# 11 - Detect all files for batch
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
        baseName = os.path.basename(fileList[i])
        splitBaseName = baseName.split(".")
        baseNameOut = splitBaseName[0]
        for x in range(1, len(splitBaseName) - additionalExtensionsToRemove - 1):
            baseNameOut = baseNameOut + "." + splitBaseName[x]
        workingDir = os.path.dirname(fileList[i]) + fileSep + baseNameOut + fileSep

        savedFilenameFile.write(fileList[i] + ',' + workingDir + "\n")
    savedFilenameFile.close()

if sectionNumber > 1 and sectionNumber != 11:
    channelFile = os.path.dirname(pyfile) + fileSep + "saveFilename.csv"
    fileList = list(csv.reader(open(channelFile)))

    if sectionNumber < 11:
        completeName = str(fileList[0][0])
        workingDir = str(fileList[0][1])

# 2 - Split File into Individual Channels Parameters
if sectionNumber == 2:
    cmd = (JIM + 'TIFF_Channel_Splitter' + fileEXE + ' \"' + workingDir + 'Raw_Image_Stack\" \"' + completeName
           + '\"  -NumberOfChannels ' + str(imStackNumberOfChannels)
           + ' -StartFrame ' + str(imStackStartFrame) + ' -EndFrame ' + str(imStackEndFrame))

    if imStackMultipleFiles:
        cmd = cmd + ' -DetectMultipleFiles'

    if imStackChannelsToTransform != '':
        cmd = (cmd + ' -Transform ' + imStackChannelsToTransform + ' ' + imStackVerticalFlipChannel + ' '
               + imStackHorizontalFlipChannel + ' ' + imStackRotateChannel)

    if imStackDisableMetadata:
        cmd = cmd + ' -DisableMetadata'

    os.system(cmd)

# 3 - Align Channels and Calculate Drifts
if sectionNumber == 3:
    allChannelNames = ''  # the string list of all channel names
    for j in range(imStackNumberOfChannels):
        allChannelNames += ' \"' + workingDir + 'Raw_Image_Stack_Channel_' + str(j + 1) + '.tif\"'

    cmd = (JIM + 'Align_Channels' + fileEXE + ' \"' + workingDir + "Alignment\"" + allChannelNames + " -Start "
           + str(alignStartFrame) + " -End " + str(alignEndFrame) + ' -Iterations ' + str(alignIterations)
           + ' -MaxShift ' + str(alignMaxShift))

    if alignManually:
        cmd = cmd + ' -Alignment ' + alignXOffset + ' ' + alignYOffset + ' ' + alignRotationAngle + ' ' + alignScalingFactor

    if alignOutputStacks:
        cmd = cmd + ' -OutputAligned'

    os.system(cmd)

    imin = Image.open(workingDir + "Alignment_Full_Projection_Before.tiff")
    plt.figure('Before Drift Correction and Alignment')

    imred = np.zeros((imin.height, imin.width))
    imgreen = np.zeros((imin.height, imin.width))
    imblue = np.zeros((imin.height, imin.width))
    for j in range(imin.n_frames):
        imin.seek(j)
        iminnp = np.array(imin).astype(float)
        iminnp = np.clip(255 * (iminnp - np.percentile(iminnp, displayMin)) / (
                np.percentile(iminnp, displayMax) - np.percentile(iminnp, displayMin)), 0, 255)
        imred = imred + overlayColours[j][0] * iminnp
        imgreen = imgreen + overlayColours[j][1] * iminnp
        imblue = imblue + overlayColours[j][2] * iminnp
    imout = np.dstack((imred, imgreen, imblue)).astype(np.uint8)

    if imStackNumberOfChannels==1:
        imout = iminnp
        plt.imshow(imout, 'gray')
    else:
        plt.imshow(imout)
    plt.show()

    imin = Image.open(workingDir + "Alignment_Full_Projection_After.tiff")
    imred = np.zeros((imin.height, imin.width))
    imgreen = np.zeros((imin.height, imin.width))
    imblue = np.zeros((imin.height, imin.width))
    for j in range(imin.n_frames):
        imin.seek(j)
        iminnp = np.array(imin).astype(float)
        iminnp = np.clip(255 * (iminnp - np.percentile(iminnp, displayMin)) / (
                np.percentile(iminnp, displayMax) - np.percentile(iminnp, displayMin)), 0, 255)
        imred = imred + overlayColours[j][0] * iminnp
        imgreen = imgreen + overlayColours[j][1] * iminnp
        imblue = imblue + overlayColours[j][2] * iminnp
    imout = np.dstack((imred, imgreen, imblue)).astype(np.uint8)

    plt.figure('After Drift Correction and Alignment')
    if imStackNumberOfChannels==1:
        imout = iminnp
        plt.imshow(imout, 'gray')
    else:
        plt.imshow(imout)
    plt.show()

# 4- Make a SubAverage of the Image Stack for Detection
if sectionNumber == 4:
    allChannelNames = ''  # the string list of all channel names
    for j in range(imStackNumberOfChannels):
        allChannelNames += ' \"' + workingDir + 'Raw_Image_Stack_Channel_' + str(j + 1) + '.tif\"'

    cmd = (JIM + 'Mean_of_Frames' + fileEXE + ' \"' + workingDir + 'Alignment_Channel_To_Channel_Alignment.csv\" \"'
           + workingDir + "Alignment_Channel_1.csv\" \"" + workingDir + "Image_For_Detection\""
           + allChannelNames + " -Start " + detectionStartFrame + " -End " + detectionEndFrame
           + ' -Weights ' + detectWeights)

    if detectUsingMaxProjection:
        cmd = cmd + ' -MaxProjection'

    os.system(cmd)

    imName = workingDir + "Image_For_Detection_Partial_Mean.tiff"
    img = mpimg.imread(imName)
    plt.figure('Sub-Average to use for detection')
    plt.imshow(img, cmap="gray")
    plt.show()

# 5 - detect particles
if sectionNumber == 5:
    cmd = (
                JIM + 'Detect_Particles' + fileEXE + ' \"' + workingDir + 'Image_For_Detection_Partial_Mean.tiff\" \"' + workingDir
                + 'Detected\" -BinarizeCutoff ' + str(detectionCutoff) + ' -minLength ' + str(
            detectMinLength) + ' -maxLength '
                + str(detectMaxLength) + ' -minCount ' + str(detectMinCount) + ' -maxCount ' + str(detectMaxCount)
                + ' -minEccentricity ' + str(detectMinEccentricity)
                + ' -maxEccentricity ' + str(detectMaxEccentricity) + ' -maxDistFromLinear ' + str(
            detectMaxDistFromLinear)
                + ' -left ' + str(detectLeftEdge) + ' -right ' + str(detectRightEdge) + ' -top ' + str(
            detectTopEdge) + ' -bottom ' + str(detectBottomEdge)
                + ' -minSeparation ' + str(detectMinSeparation))

    os.system(cmd)

    imin = []
    imin.append(Image.open(workingDir + "Image_For_Detection_Partial_Mean.tiff"))
    imin.append(Image.open(workingDir + 'Detected_Regions.tif'))
    imin.append(Image.open(workingDir + 'Detected_Filtered_Regions.tif'))
    imred = np.zeros((imin[0].height, imin[0].width))
    imgreen = np.zeros((imin[0].height, imin[0].width))
    imblue = np.zeros((imin[0].height, imin[0].width))
    for j in range(len(imin)):
        iminnp = np.array(imin[j]).astype(float)
        iminnp = np.clip(255 * (iminnp - np.percentile(iminnp, displayMin)) / (
                np.percentile(iminnp, displayMax) - np.percentile(iminnp, displayMin)), 0, 255)
        imred = imred + overlayColours[j][0] * iminnp
        imgreen = imgreen + overlayColours[j][1] * iminnp
        imblue = imblue + overlayColours[j][2] * iminnp
    imout = np.dstack((imred, imgreen, imblue)).astype(np.uint8)
    plt.figure(
        'Detected Particles - Red Original Image - Blue to White Selected ROIs - Green to Yellow->Excluded by filters')
    plt.imshow(imout)
    plt.show()

# 6 - Additional Background Detection
if sectionNumber == 6:
    if additionBackgroundDetect:

        cmd = (JIM + 'Mean_of_Frames' + fileEXE + ' \"' + workingDir + 'Alignment_Channel_To_Channel_Alignment.csv\" \"'
               + workingDir + "Alignment_Channel_1.csv\" \"" + workingDir + "Background\""
               + allChannelNames + " -Start " + additionalBackgroundStartFrame + " -End " + additionalBackgroundEndFrame
               + ' -Weights ' + additionalBackgroundWeights)

        if additionBackgroundUseMaxProjection:
            cmd = cmd + ' -MaxProjection'

        os.system(cmd)

        cmd = (
                    JIM + 'Detect_Particles' + fileEXE + ' \"' + workingDir + 'Background_Partial_Mean.tiff\" \"' + workingDir
                    + 'Background_Detected\" -BinarizeCutoff ' + str(additionBackgroundCutoff))
        os.system(cmd)

        imin = []
        imin.append(Image.open(workingDir + "Image_For_Detection_Partial_Mean.tiff"))
        imin.append(Image.open(workingDir + 'Detected_Regions.tif'))
        imin.append(Image.open(workingDir + 'Detected_Filtered_Regions.tif'))
        imred = np.zeros((imin[0].height, imin[0].width))
        imgreen = np.zeros((imin[0].height, imin[0].width))
        imblue = np.zeros((imin[0].height, imin[0].width))
        for j in range(len(imin)):
            iminnp = np.array(imin[j]).astype(float)
            iminnp = np.clip(255 * (iminnp - np.percentile(iminnp, displayMin)) / (
                    np.percentile(iminnp, displayMax) - np.percentile(iminnp, displayMin)), 0, 255)
            imred = imred + overlayColours[j][0] * iminnp
            imgreen = imgreen + overlayColours[j][1] * iminnp
            imblue = imblue + overlayColours[j][2] * iminnp
        imout = np.dstack((imred, imgreen, imblue)).astype(np.uint8)
        plt.figure(
            'Detected Background - Red Original Image - Blue to White Selected ROIs - Green to Yellow->Excluded by filters')
        plt.imshow(imout)
        plt.show()

# 7 - Expand Regions
if sectionNumber == 7:
    cmd = (JIM + 'Expand_Shapes' + fileEXE + ' "' + workingDir + 'Detected_Filtered_Positions.csv" "' + workingDir +
           'Detected_Positions.csv" "' + workingDir + 'Expanded" -boundaryDist ' + str(expandForegroundDist) +
           ' -backgroundDist ' + str(expandBackOuterDist) + ' -backInnerRadius ' + str(expandBackInnerDist))
    if additionBackgroundDetect:
        cmd = cmd + ' -extraBackgroundFile "' + workingDir + 'Background_Detected_Positions.csv"'

    if imStackNumberOfChannels > 1:
        cmd = cmd + ' -channelAlignment "' + workingDir + 'Alignment_Channel_To_Channel_Alignment.csv"'

    os.system(cmd)

    imin = []
    imin.append(Image.open(workingDir + "Image_For_Detection_Partial_Mean.tiff"))
    imin.append(Image.open(workingDir + 'Expanded_ROIs.tif'))
    imin.append(Image.open(workingDir + 'Expanded_Background_Regions.tif'))
    imred = np.zeros((imin[0].height, imin[0].width))
    imgreen = np.zeros((imin[0].height, imin[0].width))
    imblue = np.zeros((imin[0].height, imin[0].width))
    for j in range(len(imin)):
        iminnp = np.array(imin[j]).astype(float)
        iminnp = np.clip(255 * (iminnp - np.percentile(iminnp, displayMin)) / (
                np.percentile(iminnp, displayMax) - np.percentile(iminnp, displayMin)), 0, 255)
        imred = imred + overlayColours[j][0] * iminnp
        imgreen = imgreen + overlayColours[j][1] * iminnp
        imblue = imblue + overlayColours[j][2] * iminnp
    imout = np.dstack((imred, imgreen, imblue)).astype(np.uint8)
    plt.figure(
        'Detected Particles - Red Original Image - Green ROIs - Blue Background Regions')
    plt.imshow(imout)
    plt.show()

# 8 - Calculate Traces
if sectionNumber == 8:
    for j in range(imStackNumberOfChannels):
        cmd = (JIM + 'Calculate_Traces' + fileEXE + ' \"' + workingDir + 'Raw_Image_Stack_Channel_' + str(
            j + 1) + '.tif\" \"'
               + workingDir + 'Expanded_ROI_Positions_Channel_' + str(j + 1) + '.csv\" \"'
               + workingDir + 'Expanded_Background_Positions_Channel_' + str(j + 1) + '.csv\" \"'
               + workingDir + 'Channel_' + str(j + 1)
               + '\" -Drift \"' + workingDir + 'Alignment_Channel_' + str(j + 1) + '.csv\"')
        if traceVerboseOutput:
            cmd = cmd + ' -Verbose'
        os.system(cmd)

    falsetrue = ['false', 'true']
    variableString = ('Date, ' + str(datetime.date.today()) +
                      '\nadditionalExtensionsToRemove,' + str(additionalExtensionsToRemove) +
                      '\nimStackMultipleFiles,' + falsetrue[int(imStackMultipleFiles)] +
                      '\nimStackNumberOfChannels,' + str(imStackNumberOfChannels) +
                      '\nimStackDisableMetadata,' + falsetrue[int(imStackDisableMetadata)] +
                      '\nimStackStartFrame,' + str(imStackStartFrame) +
                      '\nimStackEndFrame,' + str(imStackEndFrame) +
                      '\nimStackChannelsToTransform,' + imStackChannelsToTransform +
                      '\nimStackVerticalFlipChannel,' + imStackVerticalFlipChannel +
                      '\nimStackHorizontalFlipChannel,' + imStackHorizontalFlipChannel +
                      '\nimStackRotateChannel,' + imStackRotateChannel +
                      '\nalignIterations,' + str(alignIterations) +
                      '\nalignStartFrame,' + str(alignStartFrame) +
                      '\nalignEndFrame,' + str(alignEndFrame) +
                      '\nalignMaxShift,' + str(alignMaxShift) +
                      '\nalignOutputStacks,' + falsetrue[int(alignOutputStacks)] +
                      '\nalignMaxIntensities,' + alignMaxIntensities +
                      '\nalignSNRCutoff,' + str(alignSNRCutoff) +
                      '\nalignManually,' + falsetrue[int(alignManually)] +
                      '\nalignXOffset,' + alignXOffset +
                      '\nalignYOffset,' + alignYOffset +
                      '\nalignRotationAngle,' + alignRotationAngle +
                      '\nalignScalingFactor,' + alignScalingFactor +
                      '\ndetectUsingMaxProjection,' + falsetrue[int(detectUsingMaxProjection)] +
                      '\ndetectionStartFrame,' + detectionStartFrame +
                      '\ndetectionEndFrame,' + detectionEndFrame +
                      '\ndetectWeights,' + detectWeights +
                      '\ndetectionCutoff,' + str(detectionCutoff) +
                      '\ndetectLeftEdge,' + str(detectLeftEdge) +
                      '\ndetectRightEdge,' + str(detectRightEdge) +
                      '\ndetectTopEdge,' + str(detectTopEdge) +
                      '\ndetectBottomEdge,' + str(detectBottomEdge) +
                      '\ndetectMinCount,' + str(detectMinCount) +
                      '\ndetectMaxCount,' + str(detectMaxCount) +
                      '\ndetectMinEccentricity,' + str(detectMinEccentricity) +
                      '\ndetectMaxEccentricity,' + str(detectMaxEccentricity) +
                      '\ndetectMinLength,' + str(detectMinLength) +
                      '\ndetectMaxLength,' + str(detectMaxLength) +
                      '\ndetectMaxDistFromLinear,' + str(detectMaxDistFromLinear) +
                      '\ndetectMinSeparation,' + str(detectMinSeparation) +
                      '\nadditionBackgroundDetect,' + falsetrue[int(additionBackgroundDetect)] +
                      '\nadditionBackgroundUseMaxProjection,' + falsetrue[int(additionBackgroundUseMaxProjection)] +
                      '\nadditionalBackgroundStartFrame,' + additionalBackgroundStartFrame +
                      '\nadditionalBackgroundEndFrame,' + additionalBackgroundEndFrame +
                      '\nadditionalBackgroundWeights,' + additionalBackgroundWeights +
                      '\nadditionBackgroundCutoff,' + str(additionBackgroundCutoff) +
                      '\nexpandForegroundDist,' + str(expandForegroundDist) +
                      '\nexpandBackInnerDist,' + str(expandBackInnerDist) +
                      '\nexpandBackOuterDist,' + str(expandBackOuterDist) +
                      '\ntraceVerboseOutput,' + falsetrue[int(traceVerboseOutput)])


    saveVariablesFile = open(workingDir + fileSep + "Trace_Generation_Variables.csv", "w")
    saveVariablesFile.write(variableString)
    saveVariablesFile.close()

    print('Traces Generated')

# 9 - View Traces
if sectionNumber == 9:
    imName = workingDir + "Detected_Filtered_Region_Numbers.tif"
    img = mpimg.imread(imName)
    plt.figure('Before Drift Correction')
    imPlot = plt.imshow(img, cmap="gray")

    channelFile = workingDir + "Detected_Filtered_Measurements.csv"
    measurements = list(csv.reader(open(channelFile)))

    myColours = [[0, 0.447, 0.741], [0.85, 0.325, 0.098], [0.929, 0.694, 0.125], [0.494, 0.184, 0.556], [0.466, 0.674, 0.188], [0.301, 0.745, 0.933] ,[0.635, 0.078, 0.184]]
    data = []
    scalingFactors = []
    for j in range(imStackNumberOfChannels):
        channelFile = workingDir + "Channel_"+str(j+1)+"_Fluorescent_Intensities.csv"
        channelFile = list(csv.reader(open(channelFile)))
        channelFile.pop(0)
        channelFile = np.array(channelFile).astype(float)
        scalingFactors.append(np.ceil(np.log10(np.amax(channelFile)))-2)
        data.append(np.array(channelFile).astype(float))

    plt.subplots(7,4,figsize=(17.78/2.5, 22.86/2.5), facecolor=(1, 1, 1))
    xpoints = np.arange(0.0,len(data[0][0])) * montageTimePerFrame
    yaxisLabelStr = 'Normalised Intensity'

    for i in range(1, 29):
        if len(data[0]) > i + (montagePageNumber - 1) * 28:
            plt.subplot(7, 4, i)
            if imStackNumberOfChannels>1:
                for j in range(imStackNumberOfChannels):
                    toplot = data[j][i + (montagePageNumber - 1) * 28]
                    plt.plot(xpoints, toplot / max(toplot), linewidth=2, color=myColours[j])
                plt.ylim(-0.2, 1)
            else:
                toplot = data[0][i + (montagePageNumber - 1) * 28]
                plt.plot(xpoints, toplot / pow(10, scalingFactors[0]), linewidth=2, color=myColours[0])
                yaxisLabelStr = 'Intensity (10^'+str(int(scalingFactors[0]))+' a.u.)'

            plt.plot(plt.xlim(), [0, 0], color='black')

            xpos = round(float(measurements[i + (montagePageNumber - 1) * 28][0]))
            ypos = round(float(measurements[i + (montagePageNumber - 1) * 28][1]))
            plt.title('No. ' + str(i + (montagePageNumber - 1) * 28) + ' x ' + str(xpos) + ' y ' + str(ypos), fontsize = 10, weight='bold')

    plt.annotate('Time ('+montageTimeUnits+')', xy=(0.5, 0.05), xycoords = 'figure fraction',fontsize = 14, weight='bold',horizontalalignment = 'center')
    plt.annotate(yaxisLabelStr, xy=(0.03, 0.5), xycoords='figure fraction', fontsize=14,
                 weight='bold',rotation = 90, va = 'center')
    plt.tight_layout()
    plt.subplots_adjust(wspace = 0.3,hspace = 0.75)
    if not os.path.isdir(workingDir + 'Examples'+fileSep):
        os.makedirs(workingDir + 'Examples'+fileSep)
    plt.savefig(workingDir + 'Examples'+fileSep+'Example_Page_'+str(montagePageNumber)+'.png', format = 'png', dpi = 600)
    plt.savefig(workingDir + 'Examples' + fileSep + 'Example_Page_' + str(montagePageNumber) + '.svg', format='svg')
    plt.show()

# 10 - Extract Traces
if sectionNumber == 10:
    allChannelNames = ''  # the string list of all channel names
    for j in range(imStackNumberOfChannels):
        allChannelNames += ' \"' + workingDir + 'Raw_Image_Stack_Channel_' + str(j + 1) + '.tif\"'

    cmd = (JIM + 'Isolate_Particle' + fileEXE + ' \"' + workingDir + 'Alignment_Channel_To_Channel_Alignment.csv\" \"'
           + workingDir + 'Alignment_Channel_1.csv\" \"' + workingDir + 'Detected_Filtered_Measurements.csv\" \"'
           + workingDir + 'Examples'+os.sep+'Example\" '+allChannelNames+ ' -Start '+str(montageStart)+ ' -End '+str(montageEnd)+ ' -Particle '
           + str(montageTraceNo) + ' -Delta '+str(montageDelta)+ ' -Average '+str(montageAverage))

    if montageOutputParticleImageStack:
        cmd = cmd + ' -outputImageStack'
    os.system(cmd)

    imName = (workingDir + 'Examples'+os.sep+'Example_Trace_' + str(montageTraceNo) + '_Range_' + str(montageStart) + '_' +
         str(montageDelta) + '_' + str(montageEnd) + '_montage.tiff')
    img = mpimg.imread(imName)
    plt.figure('Trace Montage')
    plt.imshow(img, cmap="gray")
    plt.show()

    myColours = [[0, 0.447, 0.741], [0.85, 0.325, 0.098], [0.929, 0.694, 0.125], [0.494, 0.184, 0.556],
                 [0.466, 0.674, 0.188], [0.301, 0.745, 0.933], [0.635, 0.078, 0.184]]

    data = []
    for j in range(imStackNumberOfChannels):
        channelFile = workingDir + "Channel_"+str(j+1)+"_Fluorescent_Intensities.csv"
        channelFile = list(csv.reader(open(channelFile)))
        channelFile.pop(0)
        data.append(np.array(channelFile).astype(float))

    plt.figure(figsize=(4, 3), facecolor=(1, 1, 1))
    xpoints = np.arange(0.0, len(data[0][0])) * montageTimePerFrame

    for j in range(imStackNumberOfChannels):
        toplot = data[j][montageTraceNo]
        plt.plot(xpoints, toplot / max(toplot), linewidth=4, color=myColours[j])

    plt.plot(plt.xlim(), [0, 0], color='black')
    plt.ylim(-0.2, 1)
    plt.xlim(min(xpoints),max(xpoints))

    plt.xlabel('Time (' + montageTimeUnits + ')', fontsize=14, weight='bold',ha='center')
    plt.ylabel('Normalised Intensity', fontsize=14,weight='bold', rotation=90, va='center')
    plt.tight_layout()

    if not os.path.isdir(workingDir + 'Examples' + fileSep):
        os.makedirs(workingDir + 'Examples' + fileSep)
    plt.savefig(workingDir + 'Examples' + fileSep + 'Example_Trace_' + str(montageTraceNo) + '.png', format='png',
                dpi=600)
    plt.savefig(workingDir + 'Examples' + fileSep + 'Example_Trace_' + str(montageTraceNo) + '.svg', format='svg')
    plt.show()

#12 - Batch Process
if sectionNumber == 12:

    def f(x):
        completeNameIn = str(fileList[x][0])
        workingDirIn = str(fileList[x][1])
        print(completeNameIn)
        print(workingDirIn)

        if not os.path.isdir(workingDirIn):
            os.makedirs(workingDirIn)

        cmdIn = (JIM + 'TIFF_Channel_Splitter' + fileEXE + ' \"' + workingDirIn + 'Raw_Image_Stack\" \"' + completeNameIn
               + '\"  -NumberOfChannels ' + str(imStackNumberOfChannels)
               + ' -StartFrame ' + str(imStackStartFrame) + ' -EndFrame ' + str(imStackEndFrame))

        if imStackMultipleFiles:
            cmdIn = cmdIn + ' -DetectMultipleFiles'
        if imStackChannelsToTransform != '':
            cmdIn = (cmdIn + ' -Transform ' + imStackChannelsToTransform + ' ' + imStackVerticalFlipChannel + ' '
                   + imStackHorizontalFlipChannel + ' ' + imStackRotateChannel)
        if imStackDisableMetadata:
            cmdIn = cmdIn + ' -DisableMetadata'

        os.system(cmdIn)

        allChannelNamesIn = ''  # the string list of all channel names
        for j in range(imStackNumberOfChannels):
            allChannelNamesIn += ' \"' + workingDirIn + 'Raw_Image_Stack_Channel_' + str(j + 1) + '.tif\"'

        cmdIn = (JIM + 'Align_Channels' + fileEXE + ' \"' + workingDirIn + "Alignment\"" + allChannelNamesIn + " -Start "
               + str(alignStartFrame) + " -End " + str(alignEndFrame) + ' -Iterations ' + str(alignIterations)
               + ' -MaxShift ' + str(alignMaxShift))
        if alignManually:
            cmdIn = cmdIn + ' -Alignment ' + alignXOffset + ' ' + alignYOffset + ' ' + alignRotationAngle + ' ' + alignScalingFactor
        if alignOutputStacks:
            cmdIn = cmdIn + ' -OutputAligned'
        os.system(cmdIn)

        cmdIn = (JIM + 'Mean_of_Frames' + fileEXE + ' \"' + workingDirIn + 'Alignment_Channel_To_Channel_Alignment.csv\" \"'
               + workingDirIn + "Alignment_Channel_1.csv\" \"" + workingDirIn + "Image_For_Detection\""
               + allChannelNamesIn + " -Start " + detectionStartFrame + " -End " + detectionEndFrame
               + ' -Weights ' + detectWeights)
        if detectUsingMaxProjection:
            cmdIn = cmdIn + ' -MaxProjection'
        os.system(cmdIn)

        cmdIn = (JIM + 'Detect_Particles' + fileEXE + ' \"' + workingDirIn + 'Image_For_Detection_Partial_Mean.tiff\" \"' + workingDirIn
                    + 'Detected\" -BinarizeCutoff ' + str(detectionCutoff) + ' -minLength ' + str(
                detectMinLength) + ' -maxLength '
                    + str(detectMaxLength) + ' -minCount ' + str(detectMinCount) + ' -maxCount ' + str(detectMaxCount)
                    + ' -minEccentricity ' + str(detectMinEccentricity)
                    + ' -maxEccentricity ' + str(detectMaxEccentricity) + ' -maxDistFromLinear ' + str(
                detectMaxDistFromLinear)
                    + ' -left ' + str(detectLeftEdge) + ' -right ' + str(detectRightEdge) + ' -top ' + str(
                detectTopEdge) + ' -bottom ' + str(detectBottomEdge)
                    + ' -minSeparation ' + str(detectMinSeparation))

        os.system(cmdIn)

        if additionBackgroundDetect:
            cmdIn = (JIM + 'Mean_of_Frames' + fileEXE + ' \"' + workingDirIn + 'Alignment_Channel_To_Channel_Alignment.csv\" \"'
                   + workingDirIn + "Alignment_Channel_1.csv\" \"" + workingDirIn + "Background\""
                   + allChannelNamesIn + " -Start " + additionalBackgroundStartFrame + " -End " + additionalBackgroundEndFrame
                   + ' -Weights ' + additionalBackgroundWeights)
            if additionBackgroundUseMaxProjection:
                cmdIn = cmdIn + ' -MaxProjection'
            os.system(cmdIn)
            cmdIn = (
                        JIM + 'Detect_Particles' + fileEXE + ' \"' + workingDirIn + 'Background_Partial_Mean.tiff\" \"' + workingDirIn
                        + 'Background_Detected\" -BinarizeCutoff ' + str(additionBackgroundCutoff))
            os.system(cmdIn)

        cmdIn = (JIM + 'Expand_Shapes' + fileEXE + ' "' + workingDirIn + 'Detected_Filtered_Positions.csv" "' + workingDirIn +
               'Detected_Positions.csv" "' + workingDirIn + 'Expanded" -boundaryDist ' + str(expandForegroundDist) +
               ' -backgroundDist ' + str(expandBackOuterDist) + ' -backInnerRadius ' + str(expandBackInnerDist))
        if additionBackgroundDetect:
            cmdIn = cmdIn + ' -extraBackgroundFile "' + workingDirIn + 'Background_Detected_Positions.csv"'

        if imStackNumberOfChannels > 1:
            cmdIn = cmdIn + ' -channelAlignment "' + workingDirIn + 'Alignment_Channel_To_Channel_Alignment.csv"'

        os.system(cmdIn)

        for j in range(imStackNumberOfChannels):
            cmdIn = (JIM + 'Calculate_Traces' + fileEXE + ' \"' + workingDirIn + 'Raw_Image_Stack_Channel_' + str(
                j + 1) + '.tif\" \"'
                   + workingDirIn + 'Expanded_ROI_Positions_Channel_' + str(j + 1) + '.csv\" \"'
                   + workingDirIn + 'Expanded_Background_Positions_Channel_' + str(j + 1) + '.csv\" \"'
                   + workingDirIn + 'Channel_' + str(j + 1)
                   + '\" -Drift \"' + workingDirIn + 'Alignment_Channel_' + str(j + 1) + '.csv\"')
            if traceVerboseOutput:
                cmdIn = cmdIn + ' -Verbose'
            os.system(cmdIn)

        falsetrue = ['false', 'true']
        variableString = ('Date, ' + str(datetime.date.today()) +
                          '\nadditionalExtensionsToRemove,' + str(additionalExtensionsToRemove) +
                          '\nimStackMultipleFiles,' + falsetrue[int(imStackMultipleFiles)] +
                          '\nimStackNumberOfChannels,' + str(imStackNumberOfChannels) +
                          '\nimStackDisableMetadata,' + falsetrue[int(imStackDisableMetadata)] +
                          '\nimStackStartFrame,' + str(imStackStartFrame) +
                          '\nimStackEndFrame,' + str(imStackEndFrame) +
                          '\nimStackChannelsToTransform,' + imStackChannelsToTransform +
                          '\nimStackVerticalFlipChannel,' + imStackVerticalFlipChannel +
                          '\nimStackHorizontalFlipChannel,' + imStackHorizontalFlipChannel +
                          '\nimStackRotateChannel,' + imStackRotateChannel +
                          '\nalignIterations,' + str(alignIterations) +
                          '\nalignStartFrame,' + str(alignStartFrame) +
                          '\nalignEndFrame,' + str(alignEndFrame) +
                          '\nalignMaxShift,' + str(alignMaxShift) +
                          '\nalignOutputStacks,' + falsetrue[int(alignOutputStacks)] +
                          '\nalignMaxIntensities,' + alignMaxIntensities +
                          '\nalignSNRCutoff,' + str(alignSNRCutoff) +
                          '\nalignManually,' + falsetrue[int(alignManually)] +
                          '\nalignXOffset,' + alignXOffset +
                          '\nalignYOffset,' + alignYOffset +
                          '\nalignRotationAngle,' + alignRotationAngle +
                          '\nalignScalingFactor,' + alignScalingFactor +
                          '\ndetectUsingMaxProjection,' + falsetrue[int(detectUsingMaxProjection)] +
                          '\ndetectionStartFrame,' + detectionStartFrame +
                          '\ndetectionEndFrame,' + detectionEndFrame +
                          '\ndetectWeights,' + detectWeights +
                          '\ndetectionCutoff,' + str(detectionCutoff) +
                          '\ndetectLeftEdge,' + str(detectLeftEdge) +
                          '\ndetectRightEdge,' + str(detectRightEdge) +
                          '\ndetectTopEdge,' + str(detectTopEdge) +
                          '\ndetectBottomEdge,' + str(detectBottomEdge) +
                          '\ndetectMinCount,' + str(detectMinCount) +
                          '\ndetectMaxCount,' + str(detectMaxCount) +
                          '\ndetectMinEccentricity,' + str(detectMinEccentricity) +
                          '\ndetectMaxEccentricity,' + str(detectMaxEccentricity) +
                          '\ndetectMinLength,' + str(detectMinLength) +
                          '\ndetectMaxLength,' + str(detectMaxLength) +
                          '\ndetectMaxDistFromLinear,' + str(detectMaxDistFromLinear) +
                          '\ndetectMinSeparation,' + str(detectMinSeparation) +
                          '\nadditionBackgroundDetect,' + falsetrue[int(additionBackgroundDetect)] +
                          '\nadditionBackgroundUseMaxProjection,' + falsetrue[int(additionBackgroundUseMaxProjection)] +
                          '\nadditionalBackgroundStartFrame,' + additionalBackgroundStartFrame +
                          '\nadditionalBackgroundEndFrame,' + additionalBackgroundEndFrame +
                          '\nadditionalBackgroundWeights,' + additionalBackgroundWeights +
                          '\nadditionBackgroundCutoff,' + str(additionBackgroundCutoff) +
                          '\nexpandForegroundDist,' + str(expandForegroundDist) +
                          '\nexpandBackInnerDist,' + str(expandBackInnerDist) +
                          '\nexpandBackOuterDist,' + str(expandBackOuterDist) +
                          '\ntraceVerboseOutput,' + falsetrue[int(traceVerboseOutput)])

        saveVariablesFile = open(workingDirIn + fileSep + "Trace_Generation_Variables.csv", "w")
        saveVariablesFile.write(variableString)
        saveVariablesFile.close()

        return 0


    if __name__ == '__main__':
        p = Pool(batchNumberOfThreads)
        p.map(f, np.arange(len(fileList)))
        print('Batch Analysis Complete')

