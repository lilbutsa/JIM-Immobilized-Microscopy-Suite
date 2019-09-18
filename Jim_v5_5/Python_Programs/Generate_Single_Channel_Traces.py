import sys
import os
import tkinter as tk
import matplotlib.pyplot as plt
import matplotlib.image as mpimg
import csv
from tkinter import filedialog
from PIL import Image, ImageMath


sectionNumber = 2
# Sections
# 1 - Select input file and create a folder for results
# 2 - Drift Correct
# 3 - Make a SubAverage of the Image Stack for Detection
# 4 - Detect Particles
# 5 - Expand Regions
# 6 - Calculate Traces
# 7 - View Traces
# 8 - Detect files for batch
# 9 - Batch Analyse

# 2 - Drift Correct Parameters
iterations = 3
alignstartframe = 1
alignendframe = 5

# 3 - Make a SubAverage of the Image Stack for Detection Parameters
usemaxprojection = False
partialstartframe = 1
partialendframe = 25

# 4 - Detect Particles Parameters
cutoff = 0.85  # The cutoff for the initial thresholding

# Filtering
left = 10  # Excluded particles closer to the edge than this. Make sure this value is larger than the maximum drift. 25 works well in most cases
right = 10  # Excluded particles closer to the edge than this. Make sure this value is larger than the maximum drift. 25 works well in most cases
top = 10  # Excluded particles closer to the edge than this. Make sure this value is larger than the maximum drift. 25 works well in most cases
bottom = 10  # Excluded particles closer to the edge than this. Make sure this value is larger than the maximum drift. 25 works well in most cases


mincount = 10  # Minimum number of pixels in a ROI to be counted as a particle. Use this to exclude speckles of background
maxcount=100  # Maximum number of pixels in a ROI to be counted as a particle. Use this to exclude aggregates

mineccentricity = -0.1  # Eccentricity of best fit ellipse goes from 0 to 1 - 0=Perfect Circle, 1 = Line. Use the Minimum to exclude round objects. Set it to any negative number to allow all round objects
maxeccentricity = 1.1  # Use the maximum to exclude long, thin objects. Set it to a value above 1 to include long, thin objects

minlength = 0  # Minimum number of pixels for the major axis of the best fit ellipse
maxlength = 100000  # Maximum number of pixels for the major axis of the best fit ellipse

maxDistFromLinear = 10000000  # Maximum distance that a pixel can diviate from the major axis.

# 5 - Expand Regions Parameters

expandinnerradius = 4.1  # Distance to dilate the ROIs by to make sure all flourescence from the ROI is measured
backgroundinnerradius = 4.1
backgroundradius = 20  # Distance to dilate beyond the ROI to measure the local background

# 6 - Calculate Traces Parameter
verboiseoutput = False

# 7 - View Traces Parameter
pagenumber = 3

# 8 - Detect files for batch
batchinsubfolders = True








# Don't touch from here
pyfile = sys.argv[0]
JIM = os.path.dirname(os.path.dirname(pyfile)) + "\\Jim_Programs\\"  #  Change if not running in original location e.g. JIM = "C:\\Users\\James\\Desktop\\Jim_v5\\Jim_Programs\\"

if sectionNumber != 1 and sectionNumber != 8:
    channelfile = os.path.dirname(pyfile)+"\\savefilename.csv"
    filelist = list(csv.reader(open(channelfile)))
    completename = filelist[0][0];
    print("Analysing "+completename)
    workingdir = os.path.dirname(completename) + "\\" + str(os.path.basename(completename).split(".", 1)[0]) + "\\"


# 1 - Select input file and create a folder for results
if sectionNumber == 1:
    root = tk.Tk()
    root.withdraw()

    completename = filedialog.askopenfilename()
    completename = completename.replace("/", "\\")
    print(completename)
    workingdir = os.path.dirname(completename)+"\\"+str(os.path.basename(completename).split(".", 1)[0])+"\\"
    print(workingdir)
    if not os.path.isdir(workingdir):
        os.makedirs(workingdir)
    savedFilenamefile = open(os.path.dirname(pyfile) + "\\savefilename.csv", "w")
    savedFilenamefile.write(completename)
    savedFilenamefile.close()

# 2 - Drift Correct
if sectionNumber == 2:

    cmd = JIM + "Align_Channels.exe \""+workingdir+"Aligned\" \"" + completename + "\" -Start " + str(alignstartframe) + " -End " + str(alignendframe)+' -Iterations '+str(iterations)
    os.system(cmd)

    imname = workingdir+"Aligned_initial_mean.tiff"
    img = mpimg.imread(imname)
    plt.figure('Before Drift Correction')
    imgplot = plt.imshow(img, cmap="gray")

    imname = workingdir+"Aligned_final_mean.tiff"
    img = mpimg.imread(imname)
    plt.figure('After Drift Correction')
    imgplot = plt.imshow(img, cmap="gray")
    plt.show()

# 3 - Make a SubAverage of the Image Stack for Detection
if sectionNumber == 3:

    maxprojectstr = ""
    if usemaxprojection:
        maxprojectstr = " -MaxProjection"

    cmd = JIM + "MeanofFrames.exe NULL \"" + workingdir + "Aligned_Drifts.csv\" \"" + workingdir + "Aligned\" \""+ completename +"\" -Start " + str(partialstartframe) + " -End " + str(partialendframe) + maxprojectstr
    os.system(cmd)

    imname = workingdir+"Aligned_Partial_Mean.tiff"
    img = mpimg.imread(imname)
    plt.figure('Sub-Average to use for detection')
    imgplot = plt.imshow(img, cmap="gray")
    plt.show()


# 4 - detect particles
if sectionNumber == 4:

    cmd = (JIM + 'Detect_Particles.exe \"' + workingdir + 'Aligned_Partial_Mean.tiff\" \"' + workingdir
           + 'Detected\" -BinarizeCutoff '+ str(cutoff) + ' -minLength ' + str(minlength) + ' -maxLength '
           + str(maxlength) + ' -minCount ' + str(mincount) + ' -maxCount ' + str(maxcount) + ' -minEccentricity ' + str(mineccentricity)
           + ' -maxEccentricity ' + str(maxeccentricity) + ' -maxDistFromLinear ' + str(maxDistFromLinear)
           + ' -left ' + str(left)+' -right ' + str(right)+' -top ' + str(top)+' -bottom ' + str(bottom))
    os.system(cmd)

    imname = workingdir+"Detected_Regions.tif"
    im1 = Image.open(imname)
    im1 = im1.convert("I")
    (minin , maxin) = im1.getextrema()
    im2 = ImageMath.eval("128*(a-c) / (b-c)", a=im1, b=maxin,c=minin)
    imname = workingdir+"Detected_Filtered_Regions.tif"
    im1 = Image.open(imname)
    im1 = im1.convert("I")
    (minin , maxin) = im1.getextrema()
    im3 = ImageMath.eval("128*(a-c) / (b-c)", a=im1, b=maxin,c=minin)
    imname = workingdir+"Aligned_Partial_Mean.tiff"
    im1 = Image.open(imname)
    im1 = im1.convert("I")
    (minin , maxin) = im1.getextrema()
    im1 = ImageMath.eval("2560*(a-c) / (b-c)-400", a=im1, b=maxin, c=minin)

    imout = Image.merge("RGB", (im1.convert("L"), im2.convert("L"), im3.convert("L")))
    plt.figure('Detected Particles')
    imgplot = plt.imshow(imout, cmap="gray")
    plt.show()




# 5 - Expand Regions
if sectionNumber == 5:
    cmd = (JIM + 'Expand_Shapes.exe \"'+ workingdir+ 'Detected_Filtered_Positions.csv\" \"'
           + workingdir+'Detected_Positions.csv\" \"'+ workingdir+ 'Expanded\" -boundaryDist '
           + str(expandinnerradius)+ ' -backgroundDist ' + str(backgroundradius)+ ' -backInnerRadius '+str(backgroundinnerradius))
    os.system(cmd)

    imname = workingdir+"Expanded_ROIs.tif"
    im1 = Image.open(imname)
    im1 = im1.convert("I")
    (minin,maxin) = im1.getextrema()
    im2 = ImageMath.eval("128*(a-c) / (b-c)", a=im1, b=maxin,c=minin)
    imname = workingdir+"Expanded_Background_Regions.tif"
    im1 = Image.open(imname)
    im1 = im1.convert("I")
    (minin,maxin) = im1.getextrema()
    im3 = ImageMath.eval("128*(a-c) / (b-c)", a=im1, b=maxin,c=minin)
    imname = workingdir+"Aligned_Partial_Mean.tiff"
    im1 = Image.open(imname)
    im1 = im1.convert("I")
    (minin,maxin) = im1.getextrema()
    im1 = ImageMath.eval("2560*(a-c) / (b-c)-400", a=im1, b=maxin, c=minin)
    imout = Image.merge("RGB", (im1.convert("L"), im2.convert("L"), im3.convert("L")))
    plt.figure('Detected Particles')
    imgplot = plt.imshow(imout, cmap="gray")
    plt.show()

# 6 - Calculate Traces
if sectionNumber == 6:
    cmd = JIM + 'Calculate_Traces.exe \"'+ completename+ '\" \"' + workingdir+ 'Expanded_ROI_Positions.csv\" \"' + workingdir +'Expanded_Background_Positions.csv\" \"'  + workingdir+ 'Channel_1\" -Drift \"' + workingdir+'Aligned_Drifts.csv\"'
    os.system(cmd)

# 7 - View Traces
if sectionNumber == 7:
    imname = workingdir+"Detected_Filtered_Region_Numbers.tif"
    img = mpimg.imread(imname)
    plt.figure('Before Drift Correction')
    imgplot = plt.imshow(img, cmap="gray")

    channelfile = workingdir+"Detected_Filtered_Measurements.csv"
    measurements = list(csv.reader(open(channelfile)))

    channelfile = workingdir+"Channel_1_Flourescent_Intensities.csv"
    data = list(csv.reader(open(channelfile)))
    plt.figure()
    for i in range(1, 37):
        if len(data) > i+(pagenumber-1)*36:
            plt.subplot(6, 6, i)
            plt.plot(data[i+(pagenumber-1)*36-1])
            xpos = round(float(measurements[i+(pagenumber-1)*36][0]))
            ypos = round(float(measurements[i+(pagenumber-1)*36][1]))
            plt.title('Particle '+str(i+(pagenumber-1)*36)+' x '+str(xpos)+' y '+str(ypos))
    mng = plt.get_current_fig_manager()
    mng.window.showMaximized()
    plt.tight_layout()
    plt.show()




# 8 - Detect files for batch
if sectionNumber == 8:
    root = tk.Tk()
    root.withdraw()
    topfolder = filedialog.askdirectory(parent=root)


    filelist = []
    if batchinsubfolders:
        for folder in os.listdir(topfolder):
            folderin = os.path.join(topfolder, folder)
            if os.path.isdir(folderin):
                for file in os.listdir(folderin):
                    if file.endswith(".tif") or file.endswith(".tiff") or file.endswith(".TIF") or file.endswith(".TIFF"):
                        filelist.append(os.path.join(folderin, file).replace("/", "\\"))
    else:
        for file in os.listdir(topfolder):
            if file.endswith(".tif") or file.endswith(".tiff") or file.endswith(".TIF") or file.endswith(".TIFF"):
                filelist.append(os.path.join(topfolder, file).replace("/", "\\"))

    print('There are ' + str(len(filelist))+' files to analyse')
    print(filelist)
    savedFilenamefile = open(os.path.dirname(pyfile) + "\\savefilename.csv", "w")
    for i in range(len(filelist)):
        savedFilenamefile.write(filelist[i]+"\n")
    savedFilenamefile.close()


if sectionNumber == 9:

    for filein in filelist:
        completename = filein[0]
        print('Analysing file '+completename)
        workingdir = os.path.dirname(completename) + "\\" + str(os.path.basename(completename).split(".", 1)[0]) + "\\"
        if not os.path.isdir(workingdir):
            os.makedirs(workingdir)

        cmd = (JIM + "Align_Channels.exe \"" + workingdir + "Aligned\" \"" + completename + "\" -Start " + str(
            alignstartframe) + " -End " + str(alignendframe) + ' -Iterations ' + str(iterations))
        os.system(cmd)

        cmd = JIM + "MeanofFrames.exe NULL \"" + workingdir + "Aligned_Drifts.csv\" \"" + workingdir + "Aligned\" \""+ completename +"\" -Start " + str(partialstartframe) + " -End " + str(partialendframe)
        os.system(cmd)

        cmd = JIM + 'Detect_Particles.exe \"' + workingdir + 'Aligned_Partial_Mean.tiff\" \"' + workingdir + 'Detected\" -BinarizeCutoff '+ str(cutoff) + ' -minLength ' + str(minlength) + ' -maxLength ' + str(maxlength) + ' -minCount ' + str(mincount) + ' -maxCount ' + str(maxcount) + ' -minEccentricity ' + str(mineccentricity)+ ' -maxEccentricity '+ str(maxeccentricity)+ ' -minDistFromEdge '+ str(maxDistFromLinear)+ ' -maxDistFromLinear '+ str(maxDistFromLinear)
        os.system(cmd)

        cmd = JIM + 'Expand_Shapes.exe \"'+ workingdir+ 'Detected_Filtered_Positions.csv\" \"'+ workingdir+'Detected_Positions.csv\" \"'+ workingdir+ 'Expanded\" -boundaryDist '+ str(expandinnerradius)+ ' -backgroundDist '+ str(backgroundradius)+ ' -backInnerRadius '+str(backgroundinnerradius)
        os.system(cmd)

        cmd = JIM + 'Calculate_Traces.exe \"'+ completename+ '\" \"' + workingdir+ 'Expanded_ROI_Positions.csv\" \"' + workingdir +'Expanded_Background_Positions.csv\" \"'  + workingdir+ 'Channel_1\" -Drift \"' + workingdir+'Aligned_Drifts.csv\"'
        os.system(cmd)

    print('Batch Analysis Completed')
