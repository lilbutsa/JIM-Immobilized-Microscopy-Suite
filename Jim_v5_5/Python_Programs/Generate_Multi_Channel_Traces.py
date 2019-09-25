import datetime
import sys
import os
import tkinter as tk
import matplotlib.pyplot as plt
import matplotlib.image as mpimg
import csv
from tkinter import filedialog
from PIL import Image, ImageMath

sectionNumber = 4
# Sections
# 1 - Select input file and create a folder for results
# 2 - Split File into Individual Channels
# 3 - Invert Second Channel
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

# 2 - Split File into Individual Channels Parameters
useMetadataFile = False
numberOfChannels = 2

# 3 - Invert Second Channel Parameters
invertChannel2 = False

# 4 - Align Channels and Calculate Drifts Parameters
iterations = 3
alignStartFrame = 1
alignEndFrame = 5

manualAlignment = False
rotationAngle = -2.86
scalingFactor = 1
xoffset = -5
yoffset = -5

# 5 - Make a SubAverage of the Image Stack for Detection Parameters
useMaxProjection = False
detectionStartFrame = 1
detectionEndFrame = 25

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
maxLength = 100000  # Maximum length of the region

maxDistFromLinear = 10000000  # Maximum distance that a pixel can deviate from the major axis.

# 8 - Expand Regions Parameters

foregroundDist = 4.1  # Distance to dilate the ROIs by to make sure all flourescence from the ROI is measured
backInnerDist = 4.1
backOuterDist = 20  # Distance to dilate beyond the ROI to measure the local background

# 9 - Calculate Traces Parameter
verboseOutput = False

# 10 - View Traces Parameter
pageNumber = 3

# 11 - Detect files for batch
filesInSubFolders = True

# 12 - Batch Analysis
overwritePreviouslyAnalysed = True

# ~~~~ Don't touch from here ~~~~ #
pyfile = sys.argv[0]
JIM = os.path.dirname(os.path.dirname(pyfile)) + "\\Jim_Programs\\"
#  Change if not running in original distribution folder e.g. JIM = "C:\\Users\\James\\Desktop\\Jim_v5\\Jim_Programs\\"

if sectionNumber != 1 and sectionNumber != 11:
    channelFile = os.path.dirname(pyfile) + "\\saveFilename.csv"
    fileList = list(csv.reader(open(channelFile)))
    completeName = fileList[0][0]
    print("Analysing " + completeName)
    workingDir = os.path.dirname(completeName) + "\\" + str(os.path.basename(completeName).split(".", 1)[0]) + "\\"

# 1 - Select input file and create a folder for results
if sectionNumber == 1:
    root = tk.Tk()
    root.withdraw()

    completeName = filedialog.askopenfilename()
    completeName = completeName.replace("/", "\\")
    print(completeName)
    workingDir = os.path.dirname(completeName) + "\\" + str(os.path.basename(completeName).split(".", 1)[0]) + "\\"
    print(workingDir)
    if not os.path.isdir(workingDir):
        os.makedirs(workingDir)
    savedFilenameFile = open(os.path.dirname(pyfile) + "\\saveFilename.csv", "w")
    savedFilenameFile.write(completeName)
    savedFilenameFile.close()

# 2 - Split File into Individual Channels Parameters
if sectionNumber == 2:
    if useMetadataFile:
        metaFileName = (os.path.dirname(completename) + "\\"
                        + str(os.path.basename(completename).split(".", 1)[0]) + '_metadata.txt')
        cmd = (JIM + 'TIFF_Channel_Splitter.exe \"' + completeName + '\" \"' + workingDir
               + 'Images\" -MetadataFile \"' + metaFileName + '\"')
    else:
        cmd = (JIM + 'TIFF_Channel_Splitter.exe \"' + completeName + '\" \"' + workingDir + 'Images\" -NumberOfChannels '
               + str(numberOfChannels))
    os.system(cmd)

# 3 - Invert Second Channel
if sectionNumber == 3 and invertChannel2:
    cmd = (JIM + 'Invert_Channel.exe "' + workingDir + 'Images_Channel_2.tiff" "' + workingDir +
           'Images_Channel_2_Inverted.tiff"')
    system(cmd)
    os.remove(workingDir + 'Images_Channel_2.tiff')
    os.rename(workingDir + 'Images_Channel_2_Inverted.tiff', workingDir + 'Images_Channel_2.tiff')

# 4 - Align Channels and Calculate Drifts
if sectionNumber == 4:
    if manualAlignment:
        cmd = (JIM + "Align_Channels.exe \"" + workingDir + "Aligned\" \"" + completeName + "\" -Start "
               + str(alignStartFrame) + " -End " + str(alignEndFrame) + ' -Iterations ' + str(iterations) +
               ' -Alignment ' + str(xoffset) + ' ' + str(yoffset) + ' ' + str(rotationAngle) + ' ' + str(scalingFactor))

    else:
        cmd = (JIM + "Align_Channels.exe \"" + workingDir + "Aligned\" \"" + completeName + "\" -Start "
               + str(alignStartFrame) + " -End " + str(alignEndFrame) + ' -Iterations ' + str(iterations))
    os.system(cmd)

    imName = workingDir + "Aligned_aligned_full_mean_1.tiff"
    im1 = Image.open(imName)
    im1 = im1.convert("I")
    (minIm, maxIm) = im1.getextrema()
    im2 = ImageMath.eval("128*(a-c) / (b-c)", a=im1, b=maxIm, c=minIm)
    imName = workingDir + "Aligned_aligned_full_mean_2.tiff"
    im1 = Image.open(imName)
    im1 = im1.convert("I")
    (minIm, maxIm) = im1.getextrema()
    im3 = ImageMath.eval("128*(a-c) / (b-c)", a=im1, b=maxIm, c=minIm)
    imName = workingDir + "Aligned_aligned_full_mean_2.tiff"
    im1 = Image.open(imName)
    im1 = im1.convert("I")
    (minIm, maxIm) = im1.getextrema()
    im1 = ImageMath.eval("0*a", a=im1)

    imOut = Image.merge("RGB", (im1.convert("L"), im2.convert("L"), im3.convert("L")))
    plt.figure('Detected Particles')
    imPlot = plt.imshow(imOut, cmap="gray")
    plt.show()

# 5 - Make a SubAverage of the Image Stack for Detection
if sectionNumber == 5:

    maxProjectionString = ""
    if useMaxProjection:
        maxProjectionString = " -MaxProjection"

    cmd = (JIM + "Mean_of_Frames.exe NULL \"" + workingDir + "Aligned_Drifts.csv\" \"" + workingDir + "Aligned\" \""
           + completeName + "\" -Start " + str(detectionStartFrame)
           + " -End " + str(detectionEndFrame) + maxProjectionString)
    os.system(cmd)

    imName = workingDir + "Aligned_Partial_Mean.tiff"
    img = mpimg.imread(imName)
    plt.figure('Sub-Average to use for detection')
    imPlot = plt.imshow(img, cmap="gray")
    plt.show()

# 6 - detect particles
if sectionNumber == 7:
    cmd = (JIM + 'Detect_Particles.exe \"' + workingDir + 'Aligned_Partial_Mean.tiff\" \"' + workingDir
           + 'Detected\" -BinarizeCutoff ' + str(cutoff) + ' -minLength ' + str(minLength) + ' -maxLength '
           + str(maxLength) + ' -minCount ' + str(minCount) + ' -maxCount ' + str(maxCount)
           + ' -minEccentricity ' + str(minEccentricity)
           + ' -maxEccentricity ' + str(maxEccentricity) + ' -maxDistFromLinear ' + str(maxDistFromLinear)
           + ' -left ' + str(left) + ' -right ' + str(right) + ' -top ' + str(top) + ' -bottom ' + str(bottom))
    os.system(cmd)

    imName = workingDir + "Detected_Regions.tif"
    im1 = Image.open(imName)
    im1 = im1.convert("I")
    (minIm, maxIm) = im1.getextrema()
    im2 = ImageMath.eval("128*(a-c) / (b-c)", a=im1, b=maxIm, c=minIm)
    imName = workingDir + "Detected_Filtered_Regions.tif"
    im1 = Image.open(imName)
    im1 = im1.convert("I")
    (minIm, maxIm) = im1.getextrema()
    im3 = ImageMath.eval("128*(a-c) / (b-c)", a=im1, b=maxIm, c=minIm)
    imName = workingDir + "Aligned_Partial_Mean.tiff"
    im1 = Image.open(imName)
    im1 = im1.convert("I")
    (minIm, maxIm) = im1.getextrema()
    im1 = ImageMath.eval("2560*(a-c) / (b-c)-400", a=im1, b=maxIm, c=minIm)

    imOut = Image.merge("RGB", (im1.convert("L"), im2.convert("L"), im3.convert("L")))
    plt.figure('Detected Particles')
    imPlot = plt.imshow(imOut, cmap="gray")
    plt.show()

# 8 - Expand Regions
if sectionNumber == 8:
    cmd = (JIM + 'Expand_Shapes.exe \"' + workingDir + 'Detected_Filtered_Positions.csv\" \"'
           + workingDir + 'Detected_Positions.csv\" \"' + workingDir + 'Expanded\" -boundaryDist '
           + str(foregroundDist) + ' -backgroundDist ' + str(backOuterDist) + ' -backInnerRadius ' + str(backInnerDist))
    os.system(cmd)

    imName = workingDir + "Expanded_ROIs.tif"
    im1 = Image.open(imName)
    im1 = im1.convert("I")
    (minIm, maxIm) = im1.getextrema()
    im2 = ImageMath.eval("128*(a-c) / (b-c)", a=im1, b=maxIm, c=minIm)
    imName = workingDir + "Expanded_Background_Regions.tif"
    im1 = Image.open(imName)
    im1 = im1.convert("I")
    (minIm, maxIm) = im1.getextrema()
    im3 = ImageMath.eval("128*(a-c) / (b-c)", a=im1, b=maxIm, c=minIm)
    imName = workingDir + "Aligned_Partial_Mean.tiff"
    im1 = Image.open(imName)
    im1 = im1.convert("I")
    (minIm, maxIm) = im1.getextrema()
    im1 = ImageMath.eval("2560*(a-c) / (b-c)-400", a=im1, b=maxIm, c=minIm)
    imOut = Image.merge("RGB", (im1.convert("L"), im2.convert("L"), im3.convert("L")))
    plt.figure('Detected Particles')
    imPlot = plt.imshow(imOut, cmap="gray")
    plt.show()

# 9 - Calculate Traces
if sectionNumber == 9:
    cmd = (JIM + 'Calculate_Traces.exe \"' + completeName + '\" \"' + workingDir + 'Expanded_ROI_Positions.csv\" \"'
           + workingDir + 'Expanded_Background_Positions.csv\" \"' + workingDir + 'Channel_1\" -Drift \"'
           + workingDir + 'Aligned_Drifts.csv\"')
    os.system(cmd)

    variableString = ('Date, ' + str(datetime.date.today()) + '\n' +
                      'iterations,' + str(iterations) + '\nalignStartFrame,' + str(
                alignStartFrame) + '\nalignEndFrame,' +
                      str(alignEndFrame) + '\n' +
                      'useMaxProjection,' + str(int(useMaxProjection)) + '\ndetectionStartFrame,' + str(
                detectionStartFrame) +
                      '\ndetectionEndFrame,' + str(detectionEndFrame) + '\n' +
                      'cutoff,' + str(cutoff) + '\nleft,' + str(left) + '\nright,' + str(right) + '\ntop,' + str(top) +
                      '\nbottom,' + str(bottom) + '\n' +
                      'minCount,' + str(minCount) + '\nmaxCount,' + str(maxCount) + '\nminEccentricity,' +
                      str(minEccentricity) + '\nmaxEccentricity,' + str(maxEccentricity) + '\n' +
                      'minLength,' + str(minLength) + '\nmaxLength,' + str(maxLength) + '\nmaxDistFromLinear,' +
                      str(maxDistFromLinear) + '\n' +
                      'foregroundDist,' + str(foregroundDist) + '\nbackInnerDist,' + str(
                backInnerDist) + '\nbackOuterDist,' +
                      str(backOuterDist) + '\nverboseOutput,' + str(int(verboseOutput)))

    saveVariablesFile = open(workingDir + "\\Trace_Generation_Variables.csv", "w")
    saveVariablesFile.write(variableString)
    saveVariablesFile.close()

# 10 - View Traces
if sectionNumber == 7:
    imName = workingDir + "Detected_Filtered_Region_Numbers.tif"
    img = mpimg.imread(imName)
    plt.figure('Before Drift Correction')
    imPlot = plt.imshow(img, cmap="gray")

    channelFile = workingDir + "Detected_Filtered_Measurements.csv"
    measurements = list(csv.reader(open(channelFile)))

    channelFile = workingDir + "Channel_1_Fluorescent_Intensities.csv"
    data = list(csv.reader(open(channelFile)))
    plt.figure()
    for i in range(1, 37):
        if len(data) > i + (pageNumber - 1) * 36:
            plt.subplot(6, 6, i)
            plt.plot(data[i + (pageNumber - 1) * 36 - 1])
            xpos = round(float(measurements[i + (pageNumber - 1) * 36][0]))
            ypos = round(float(measurements[i + (pageNumber - 1) * 36][1]))
            plt.title('Particle ' + str(i + (pageNumber - 1) * 36) + ' x ' + str(xpos) + ' y ' + str(ypos))
    mng = plt.get_current_fig_manager()
    mng.window.showMaximized()
    plt.tight_layout()
    plt.show()

# 8 - Detect files for batch
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
                        fileList.append(os.path.join(folderin, file).replace("/", "\\"))
    else:
        for file in os.listdir(topFolder):
            if file.endswith(".tif") or file.endswith(".tiff") or file.endswith(".TIF") or file.endswith(".TIFF"):
                fileList.append(os.path.join(topFolder, file).replace("/", "\\"))

    print('There are ' + str(len(fileList)) + ' files to analyse')
    print(fileList)
    savedFilenameFile = open(os.path.dirname(pyfile) + "\\saveFilename.csv", "w")
    for i in range(len(fileList)):
        savedFilenameFile.write(fileList[i] + "\n")
    savedFilenameFile.close()

if sectionNumber == 12:

    maxProjectionString = ""
    if useMaxProjection:
        maxProjectionString = " -MaxProjection"

    for filein in fileList:
        completeName = filein[0]
        print('Analysing file ' + completeName)
        workingDir = os.path.dirname(completeName) + "\\" + str(os.path.basename(completeName).split(".", 1)[0]) + "\\"
        if not os.path.isdir(workingDir):
            os.makedirs(workingDir)

        cmd = (JIM + "Align_Channels.exe \"" + workingDir + "Aligned\" \"" + completeName + "\" -Start "
               + str(alignStartFrame) + " -End " + str(alignEndFrame) + ' -Iterations ' + str(iterations))
        os.system(cmd)

        cmd = (JIM + "Mean_of_Frames.exe NULL \"" + workingDir + "Aligned_Drifts.csv\" \"" + workingDir + "Aligned\" \""
               + completeName + "\" -Start " + str(detectionStartFrame)
               + " -End " + str(detectionEndFrame) + maxProjectionString)
        os.system(cmd)

        cmd = (JIM + 'Detect_Particles.exe \"' + workingDir + 'Aligned_Partial_Mean.tiff\" \"' + workingDir
               + 'Detected\" -BinarizeCutoff ' + str(cutoff) + ' -minLength ' + str(minLength) + ' -maxLength '
               + str(maxLength) + ' -minCount ' + str(minCount) + ' -maxCount ' + str(maxCount)
               + ' -minEccentricity ' + str(minEccentricity)
               + ' -maxEccentricity ' + str(maxEccentricity) + ' -maxDistFromLinear ' + str(maxDistFromLinear)
               + ' -left ' + str(left) + ' -right ' + str(right) + ' -top ' + str(top) + ' -bottom ' + str(bottom))
        os.system(cmd)

        cmd = (JIM + 'Expand_Shapes.exe \"' + workingDir + 'Detected_Filtered_Positions.csv\" \"'
               + workingDir + 'Detected_Positions.csv\" \"' + workingDir + 'Expanded\" -boundaryDist '
               + str(foregroundDist) + ' -backgroundDist ' + str(backOuterDist) + ' -backInnerRadius ' + str(
                    backInnerDist))
        os.system(cmd)

        cmd = (JIM + 'Calculate_Traces.exe \"' + completeName + '\" \"' + workingDir + 'Expanded_ROI_Positions.csv\" \"'
               + workingDir + 'Expanded_Background_Positions.csv\" \"' + workingDir + 'Channel_1\" -Drift \"'
               + workingDir + 'Aligned_Drifts.csv\"')
        os.system(cmd)

        variableString = ('Date, ' + str(datetime.date.today()) + '\n' +
                          'iterations,' + str(iterations) + '\nalignStartFrame,' + str(
                    alignStartFrame) + '\nalignEndFrame,' +
                          str(alignEndFrame) + '\n' +
                          'useMaxProjection,' + str(int(useMaxProjection)) + '\ndetectionStartFrame,' + str(
                    detectionStartFrame) +
                          '\ndetectionEndFrame,' + str(detectionEndFrame) + '\n' +
                          'cutoff,' + str(cutoff) + '\nleft,' + str(left) + '\nright,' + str(right) + '\ntop,' + str(
                    top) +
                          '\nbottom,' + str(bottom) + '\n' +
                          'minCount,' + str(minCount) + '\nmaxCount,' + str(maxCount) + '\nminEccentricity,' +
                          str(minEccentricity) + '\nmaxEccentricity,' + str(maxEccentricity) + '\n' +
                          'minLength,' + str(minLength) + '\nmaxLength,' + str(maxLength) + '\nmaxDistFromLinear,' +
                          str(maxDistFromLinear) + '\n' +
                          'foregroundDist,' + str(foregroundDist) + '\nbackInnerDist,' + str(
                    backInnerDist) + '\nbackOuterDist,' +
                          str(backOuterDist) + '\nverboseOutput,' + str(int(verboseOutput)))

        saveVariablesFile = open(workingDir + "\\Trace_Generation_Variables.csv", "w")
        saveVariablesFile.write(variableString)
        saveVariablesFile.close()

    print('Batch Analysis Completed')
