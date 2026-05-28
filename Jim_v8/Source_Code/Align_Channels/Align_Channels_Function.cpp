#include "BLTiffIO.h"
#include "BLImageTransform.h"
#include "writeChannelAlignment.hpp"

void driftCorrect(BLTiffIO::MultiTiffInput& input, size_t posIn, int chanIn, const std::vector< std::vector<float>>& alignment, std::vector< std::vector<float>>& drifts, const float& maxShift, std::vector<float>& referenceImage, std::vector<std::vector<float>>& outputImage, const std::string& alignedStackNameBase);
std::vector< std::vector<float>> findAlignment(std::vector< std::vector<float>>& prealignmentReference, uint32_t imageWidth, uint32_t imageHeight, float maxShift);

int Align_Channels(std::string fileName,  int startFrame, int endFrame,size_t positionIn, std::vector<std::vector<float>>& alignments, bool skipIndependentDrifts, float maxShift, bool outputAligned, int numOfChannels = 1,bool filesSplitByChannelIn = false,std::string outputBaseString="")
{
	/*
	std::cout <<"filename = "<< fileName << "\n";
	std::cout << "startFrame = " << startFrame << "\n";
	std::cout << "endFrame = " << endFrame << "\n";
	std::cout << "positionIn = " << positionIn << "\n";
	std::cout << "alignments = \n";
	for (int i = 0; i < alignments.size(); i++) {
		for (int j = 0; j < alignments[i].size(); j++)std::cout << alignments[i][j] << " ";
		std::cout << "\n";
	}
	std::cout << "skipIndependentDrifts = " << skipIndependentDrifts << "\n";
	std::cout << "maxShift = " << maxShift << "\n";
	std::cout << "outputAligned = " << outputAligned << "\n";
	std::cout << "numOfChannels = " << numOfChannels << "\n";
	std::cout << "filesSplitByChannelIn = " << filesSplitByChannelIn << "\n";
	*/

	//Aim only open each file twice (thrice if auto alignment)
	//once to make sub average, once to align everything
	//also removing initial full stack as it requires a full read
	BLTiffIO::MultiTiffInput allFiles(fileName, numOfChannels, filesSplitByChannelIn);

	size_t totalPositions = allFiles.positionNames.size();
	size_t imageWidth, imageHeight, imagePoints, imageDepth, numOfChan,numOfFrame,numOfZ;
	allFiles.imageInfo(0, imageWidth, imageHeight, imageDepth, numOfChan, numOfFrame, numOfZ);

	std::vector<std::string> allFolderNames;
	
	if(allFiles.path.back()=='/' || allFiles.path.back() == '\\')
		for (size_t posCount = 0; posCount < totalPositions; posCount++)
			allFolderNames.push_back(allFiles.path + allFiles.positionNames[posCount]);
	else
		for (size_t posCount = 0; posCount < totalPositions; posCount++)
			allFolderNames.push_back(allFiles.path + allFiles.filesep + allFiles.positionNames[posCount]);
	
	BLCSVIO::writeStringList(allFiles.path + allFiles.filesep + "PositionNameList.csv", allFolderNames);


	//Sanitize all inputs
	if(allFiles.allFilesFound==false) {
		std::cout << "Aborting as a file was not found\n";
		return 1;
	}
	if (alignments.size() > 0 && alignments.size() < numOfChan - 1) {
		std::cout << "ERROR - Alignment requires an alignment for each channel, exlcuding channel one OR an empty vector to autodetect alignment\n";
		return 2;
	}
	else if (alignments.size() > numOfChan - 1) {
		std::cout << "Warning - more alignments supplied than channels. Ignoring extra alignments\n";
		alignments.resize(numOfChan - 1);
	}
	for(size_t i=0;i< alignments.size();i++)
		if (alignments[i].size() != 4) {
			std::cout << "ERROR - Input Alignment requires four values for each channel, X Y Rotation Scale\n";
			return 3;
		}

	if (positionIn > totalPositions) {
		std::cout << "ERROR : Input position (" << positionIn << ") is greater than the detected number of positions in the data (" << totalPositions << ")\n";
		return 1;
	}

	for (size_t posCount = (positionIn == 0 ? 0 : positionIn-1); posCount < (positionIn == 0 ? totalPositions : positionIn); posCount++) {

		std::cout << "Analysing Position "<< posCount +1<<" : "<< allFiles.positionNames[posCount] <<"\n";

		allFiles.imageInfo(posCount, imageWidth, imageHeight, imageDepth, numOfChan, numOfFrame, numOfZ);
		imagePoints = imageWidth * imageHeight;

		if (numOfChan == 1)alignments = std::vector<std::vector<float>>();

		size_t startFrameIn = startFrame < 0 ? numOfFrame - startFrame : startFrame-1;
		size_t endFrameIn = endFrame < 0 ? numOfFrame - endFrame+1 : endFrame;

		std::vector<float> imagein(imagePoints, 0), imagetoalign(imagePoints, 0), outputImage(imagePoints, 0);
		std::vector< std::vector<float> > prealignmentReference(numOfChan, std::vector<float>(imagePoints, 0)), imageOut(numOfChan, std::vector<float>(imagePoints, 0));
		imageTransform_32f transformclass(imageWidth, imageHeight);

		if (outputBaseString == "")outputBaseString = "Aligned";

		//make output image files
		std::string myFolderName = allFiles.path + allFiles.filesep+ allFiles.positionNames[posCount];
		if (!std::filesystem::exists(myFolderName))std::filesystem::create_directories(myFolderName);
		std::string fileBase = myFolderName + allFiles.filesep + outputBaseString;

		std::string filenameOut = fileBase + "_Reference_Frames_Before.tiff";
		BLTiffIO::TiffOutput BeforePartial(filenameOut, imageWidth, imageHeight, 16);

		std::vector<std::vector<float>> drifts;

		//make initial stack for alignment
		std::cout << "Creating Initial Mean\n";
		for (int chancount = 0; chancount < numOfChan; chancount++) {
			for (int imcount = startFrameIn; imcount < endFrameIn; imcount++) {//sum frames for each channel
				allFiles.read1dImage(posCount, imcount, chancount, 0, imagein);
				std::transform(prealignmentReference[chancount].begin(), prealignmentReference[chancount].end(), imagein.begin(), prealignmentReference[chancount].begin(), std::plus<float>());
			}
			float divisor = (float)(endFrameIn - startFrameIn);
			std::transform(prealignmentReference[chancount].begin(), prealignmentReference[chancount].end(), prealignmentReference[chancount].begin(), [divisor](float val) { return val / divisor; });
			
			BeforePartial.write1dImage(prealignmentReference[chancount]);
		}
		
		//calculate channel alignment if not supplied
		if (alignments.size() == 0 && numOfChan > 1) {
			//use aligned full stack for reference if specified
			if (skipIndependentDrifts == false) {
				for (int chancount = 0; chancount < numOfChan; chancount++) {

					driftCorrect(allFiles,posCount,chancount, alignments, drifts, maxShift, prealignmentReference[chancount], imageOut, "");
					prealignmentReference[chancount] = imageOut[chancount];
				}
			}

			alignments = findAlignment(prealignmentReference, imageWidth, imageHeight, maxShift);

		}
		//end calculating channel alignment

		//make reference image by transforming and summing my partial reference images

		imagetoalign = prealignmentReference[0];
		for (int chancount = 1; chancount < numOfChan; chancount++) {

			//add align to mean aligned image for each channel
			transformclass.transform(prealignmentReference[chancount], imagein, -alignments[chancount - 1][0], -alignments[chancount - 1][1], alignments[chancount - 1][2], alignments[chancount - 1][3]);
			std::transform(imagetoalign.begin(), imagetoalign.end(), imagein.begin(), imagetoalign.begin(), std::plus<float>());
		}


		//string to save output stack if required
		std::string outputAlignedString = "";
		if (outputAligned)outputAlignedString = fileBase;
		//drift correct stack
		std::cout << "Aligning Stack\n";
		driftCorrect(allFiles, posCount, -1, alignments, drifts, maxShift, imagetoalign, imageOut, outputAlignedString);

		//output results
		writeChannelAlignment(fileBase, alignments, imageWidth, imageHeight);
		//writeDrifts(fileBase, drifts, alignments, imageWidth, imageHeight);
		std::string myFileName = fileBase + "_Drifts.csv";
		BLCSVIO::writeCSV(myFileName, drifts, "X Drift, Y Drift\n");

		//write out aligned full stack images
		filenameOut = fileBase + "_Full_Projection_After.tiff";
		BLTiffIO::TiffOutput AfterFull(filenameOut, imageWidth, imageHeight, 16);
		for (int chancount = 0; chancount < numOfChan; chancount++)AfterFull.write1dImage(imageOut[chancount]);

	}

	
	return 0;
}