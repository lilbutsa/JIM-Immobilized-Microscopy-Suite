import sys
import os
import tkinter as tk
from tkinter import filedialog
from PIL import Image, ImageMath, ImageTk

# Adjust these variables
# Channel Splitting

usemetadatafile = True # Set to true to read in a micromanager metadata file to ensure the tiff is split correctly. If this is not used the program assumes the tiff stack is saved in order
numberofchannels = 2;

#Alignment
alignmanstartend = True
alignstartframe = 1
alignendframe = 1

#Partial Mean
partialstartframe = 1  # First frame in statck to take average from (First frame is 1)
partialendframe = 100  # Last frame in stack to take average up to (Make sure this value is not more then the total number of frames)

#Particle Detection
# Thresholding
cutoff = 1.5 # The cutoff for the initial thresholding

# Filtering

mindistfromedge = 25  # Excluded particles closer to the edge than this. Make sure this value is larger than the maximum drift. 25 works well in most cases

mincount = 10  # Minimum number of pixels in a ROI to be counted as a particle. Use this to exclude speckles of background
maxcount = 1000000  # Maximum number of pixels in a ROI to be counted as a particle. Use this to exclude aggregates

mineccentricity = -0.1  # Eccentricity of best fit ellipse goes from 0 to 1 - 0=Perfect Circle, 1 = Line. Use the Minimum to exclude round objects. Set it to any negative number to allow all round objects
maxeccentricity = 0.4  # Use the maximum to exclude long, thin objects. Set it to a value above 1 to include long, thin objects

minlength = 0  # Minimum number of pixels for the major axis of the best fit ellipse
maxlength = 1000000  # Maximum number of pixels for the major axis of the best fit ellipse

maxDistFromLinear = 100000  # Maximum distance that a pixel can diviate from the major axis.

# expand shapes

expandinnerradius = 4.1  # Distance to dilate the ROIs by to make sure all flourescence from the ROI is measured
backgroundradius = 20  # Distance to dilate beyond the ROI to measure the local background
backgroundinnerradius = 0




# Don't touch from here

# get jim location an initial file to analyse
root = tk.Tk()
root.withdraw()
pyfile = sys.argv[0]
JIM = os.path.dirname(os.path.dirname(pyfile))+"\\Jim_Programs\\"
JIM = "C:\\Users\\James\\Desktop\\Jim_v5\\Jim_Programs\\"

#
# # create the working directory

completename = filedialog.askopenfilename()
completename = completename.replace("/", "\\")
print(completename)
workingdir = os.path.dirname(completename)+"\\"+str(os.path.basename(completename).split(".", 1)[0])+"\\"
print(workingdir)
if not os.path.isdir(workingdir):
    os.makedirs(workingdir)

# Split channels
alreadyrun = os.path.isfile(workingdir+"Images_Channel_1.tiff")
if alreadyrun:
    print("Images have already been split")
    wait = input("Enter r to resplit image stack or any other key to skip")
    if wait == "r":
        alreadyrun = False

if not alreadyrun:
    if usemetadatafile:
        metafilename = os.path.dirname(completename)+"\\" + str(os.path.basename(completename).split(".", 1)[0]) + '_metadata.txt'
        cmd = JIM+ 'TIFFChannelSplitter.exe \"'+ completename+ '\" \"'+ workingdir+ 'Images\" -MetadataFile \"'+metafilename+ '\"'
    else:
        cmd = JIM+ 'TIFFChannelSplitter.exe \"'+ completename+ '\" \"'+ workingdir+ 'Images\" -NumberOfChannels '+ str(numberofchannels)
    os.system(cmd)
    wait = input("Enter q to to quit or any other key to continue")
    print(wait)
    if wait == "q":
        sys.exit("Exited after image stack splitting")


# Calculate Drifts

alreadyrun = os.path.isfile(workingdir+"Aligned_final_mean_1.tiff")
if alreadyrun:
    print("Drift correction has already run")
    wait = input("Enter r to rerun Drift Correction or any other key to skip")
    if wait == "r":
        alreadyrun = False

if not alreadyrun:
    if alignmanstartend:
        cmd = JIM + "Align_Channels.exe \""+workingdir+"Aligned\" \"" + completename + "\" -Start " + str(alignstartframe) + " -End " + str(alignendframe)
    else:
        cmd = JIM + "Align_Channels.exe \"" + workingdir + "Aligned\" \"" + completename + "\""
    os.system(cmd)

    try:
        root.destroy()
    except:
        pass
    root = filedialog.Tk()
    imname = workingdir+"Aligned_final_mean_1.tiff"
    im1 = Image.open(imname)
    im1 = im1.convert("I")
    (minin,maxin) = im1.getextrema()
    im1 = ImageMath.eval("256*(a-c) / (b-c)", a=im1, b=maxin,c=minin)
    im1 = ImageTk.PhotoImage(im1)
    filedialog.Label(root, image=im1).grid(row=0, column=0)
    root.mainloop()

    # see if the user wants to exit
    wait = input("Enter q to to quit or any other key to continue")
    print(wait)
    if wait == "q":
        sys.exit("Exited after drift correction")

# Make a SubAverage of frames where all particles are present

alreadyrun = os.path.isfile(workingdir+"Aligned_Partial_Mean.tiff")
if alreadyrun:
    print("Sub average has already been made")
    wait = input("Enter r to remake sub average or any other key to skip")
    if wait == "r":
        alreadyrun = False

if not alreadyrun:
    cmd = JIM + "MeanofFrames.exe NULL \"" + workingdir + "Aligned_Drifts.csv\" \"" + workingdir + "Aligned\" \""+ completename +"\" -Start " + str(partialstartframe) + " -End " + str(partialendframe)
    os.system(cmd)

    try:
        root.destroy()
    except:
        pass
    root = filedialog.Tk()
    imname = workingdir+"Aligned_Partial_Mean.tiff"
    im1 = Image.open(imname)
    im1 = im1.convert("I")
    (minin,maxin) = im1.getextrema()
    im1 = ImageMath.eval("256*(a-c) / (b-c)", a=im1, b=maxin,c=minin)
    im1 = ImageTk.PhotoImage(im1)
    filedialog.Label(root, image=im1).grid(row=0, column=0)
    root.mainloop()

    # see if the user wants to exit
    wait = input("Enter q to to quit or any other key to continue")
    print(wait)
    if wait == "q":
        sys.exit("Exited after partial mean")

# detect particles

alreadyrun = os.path.isfile(workingdir+"Detected_Regions.tif")
if alreadyrun:
    print("Particles have already been detected")
    wait = input("Enter r to redetect or any other key to skip")
    if wait == "r":
        alreadyrun = False

if not alreadyrun:
    cmd = JIM + 'Detect_Particles.exe \"' + workingdir + 'Aligned_Partial_Mean.tiff\" \"' + workingdir + 'Detected\" -BinarizeCutoff '+ str(cutoff) + ' -minLength ' + str(minlength) + ' -maxLength ' + str(maxlength) + ' -minCount ' + str(mincount) + ' -maxCount ' + str(maxcount) + ' -minEccentricity ' + str(mineccentricity)+ ' -maxEccentricity '+ str(maxeccentricity)+ ' -minDistFromEdge '+ str(mindistfromedge)+ ' -maxDistFromLinear '+ str(maxDistFromLinear)
    os.system(cmd)

    try:
        root.destroy()
    except:
        pass
    root = filedialog.Tk()
    imname = workingdir+"Detected_Regions.tif"
    im1 = Image.open(imname)
    im1 = im1.convert("I")
    (minin,maxin) = im1.getextrema()
    im2 = ImageMath.eval("128*(a-c) / (b-c)", a=im1, b=maxin,c=minin)
    imname = workingdir+"Detected_Filtered_Regions.tif"
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


    im1 = ImageTk.PhotoImage(imout)


    filedialog.Label(root, image=im1).grid(row=0, column=0)
    root.mainloop()

    # see if the user wants to exit
    wait = input("Enter q to to quit or any other key to continue")
    print(wait)
    if wait == "q":
        sys.exit("Exited after partial mean")

# Expand Areas around each shape

alreadyrun = os.path.isfile(workingdir+"Expanded_ROIs.tif")
if alreadyrun:
    print("Areas have already been expanded")
    wait = input("Enter r to reexpand areas or any other key to skip")
    if wait == "r":
        alreadyrun = False

if not alreadyrun:
    cmd = JIM + 'Expand_Shapes.exe \"'+ workingdir+ 'Detected_Filtered_Positions.csv\" \"'+ workingdir+'Detected_Positions.csv\" \"'+ workingdir+ 'Expanded\" -boundaryDist '+ str(expandinnerradius)+ ' -backgroundDist '+ str(backgroundradius)+ ' -backInnerRadius '+str(backgroundinnerradius)
    os.system(cmd)

    try:
        root.destroy()
    except:
        pass
    root = filedialog.Tk()
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


    im1 = ImageTk.PhotoImage(imout)


    filedialog.Label(root, image=im1).grid(row=0, column=0)
    root.lift()
    root.mainloop()

    # see if the user wants to exit
    wait = input("Enter q to to quit or any other key to continue")
    print(wait)
    if wait == "q":
        sys.exit("Exited after expanding Shapes")


alreadyrun = os.path.isfile(workingdir+"Channel_1_Traces.csv")
if alreadyrun:
    print("Traces have already been made")
    wait = input("Enter r to recalculate traces or any other key to skip")
    if wait == "r":
        alreadyrun = False

if not alreadyrun:
    cmd = JIM + 'Calculate_Traces.exe \"'+ completename+ '\" \"' + workingdir+ 'Expanded_ROI_Positions.csv\" \"' + workingdir +'Expanded_Background_Positions.csv\" \"'  + workingdir+ 'Channel_1\" -Drifts \"' + workingdir+'Aligned_Drifts.csv\"'
    os.system(cmd)

    # see if the user wants to exit
    wait = input("Enter q to to quit or any other key to continue")
    if wait == "q":
        sys.exit("Exited after making traces")

# Detect files for batch

filedetect = True
filelist = []
while filedetect:
    try:
        root.destroy()
    except:
        pass
    root = tk.Tk()
    root.withdraw()
    root.focus_force()
    topfolder = filedialog.askdirectory(parent=root)

    batchinsubfolders = False
    wait = input("Enter y if files are subfolders or any other key if directly in file")
    if wait == "y":
        batchinsubfolders = True

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
    filedetect = False
    wait = input("Enter r to redetect files or any other key to continue")
    if wait == "r":
        filedetect = True


for filein in filelist:
    completename = filein
    print('Analysing file '+completename)
    workingdir = os.path.dirname(completename) + "\\" + str(os.path.basename(completename).split(".", 1)[0]) + "\\"
    if not os.path.isdir(workingdir):
        os.makedirs(workingdir)

    if alignmanstartend:
        cmd = JIM + "Align_Channels.exe \""+workingdir+"Aligned\" \"" + completename + "\" -Start " + str(alignstartframe) + " -End " + str(alignendframe)
    else:
        cmd = JIM + "Align_Channels.exe \"" + workingdir + "Aligned\" \"" + completename + "\""
    os.system(cmd)

    cmd = JIM + "MeanofFrames.exe NULL \"" + workingdir + "Aligned_Drifts.csv\" \"" + workingdir + "Aligned\" \""+ completename +"\" -Start " + str(partialstartframe) + " -End " + str(partialendframe)
    os.system(cmd)

    cmd = JIM + 'Detect_Particles.exe \"' + workingdir + 'Aligned_Partial_Mean.tiff\" \"' + workingdir + 'Detected\" -BinarizeCutoff '+ str(cutoff) + ' -minLength ' + str(minlength) + ' -maxLength ' + str(maxlength) + ' -minCount ' + str(mincount) + ' -maxCount ' + str(maxcount) + ' -minEccentricity ' + str(mineccentricity)+ ' -maxEccentricity '+ str(maxeccentricity)+ ' -minDistFromEdge '+ str(mindistfromedge)+ ' -maxDistFromLinear '+ str(maxDistFromLinear)
    os.system(cmd)

    cmd = JIM + 'Expand_Shapes.exe \"'+ workingdir+ 'Detected_Filtered_Positions.csv\" \"'+ workingdir+'Detected_Positions.csv\" \"'+ workingdir+ 'Expanded\" -boundaryDist '+ str(expandinnerradius)+ ' -backgroundDist '+ str(backgroundradius)+ ' -backInnerRadius '+str(backgroundinnerradius)
    os.system(cmd)

    cmd = JIM + 'Calculate_Traces.exe \"'+ completename+ '\" \"' + workingdir+ 'Expanded_ROI_Positions.csv\" \"' + workingdir +'Expanded_Background_Positions.csv\" \"'  + workingdir+ 'Channel_1\" -Drifts \"' + workingdir+'Aligned_Drifts.csv\"'
    os.system(cmd)

print('Batch Analysis Completed')
