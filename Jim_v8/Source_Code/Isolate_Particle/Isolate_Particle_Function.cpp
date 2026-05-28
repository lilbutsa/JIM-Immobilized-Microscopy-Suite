#include <string>
#include <iostream>
#include <vector>
#include <algorithm>
#include "BLTiffIO.h"
#include "BLImageTransform.h"
#include "BLCSVIO.h"


int Isolate_Particle(std::string fileName, size_t positionIn, size_t particle, int startFrame = 1, int endFrame = -1, size_t numMontageImages = 10, bool bOutputImageStack = false, size_t numOfChannels = 1,bool filesSplitByChannelIn = false, std::string driftfile = "", std::string alignfile = "", std::string measurementsfile = "",std::string outputfile = "") {

	BLTiffIO::MultiTiffInput allFiles(fileName, numOfChannels, filesSplitByChannelIn);

	size_t totalPositions = allFiles.positionNames.size();


	if (allFiles.allFilesFound == false) {
		std::cout << "Aborting as a file was not found\n";
		return 1;
	}
	if (positionIn > totalPositions || positionIn == 0) {
		std::cout << "ERROR : Input position (" << positionIn << ") must be between 1 and the detected number of positions in the data (" << totalPositions << ")\n";
		return 1;
	}

	size_t imageWidth, imageHeight, imagePoints, imageDepth, numOfChan, numOfFrame, numOfZ;
	allFiles.imageInfo(positionIn - 1, imageWidth, imageHeight, imageDepth, numOfChan, numOfFrame, numOfZ);

	imagePoints = imageWidth * imageHeight;

	

	std::vector< std::vector<double> > measurements(numOfFrame, std::vector<double>(19, 0.0)), drifts(numOfFrame, std::vector<double>(2, 0.0));
	std::vector< std::vector<double> >channelalignment(numOfChan - 1, {0.0,0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,(double)imageWidth/2,(double)imageHeight/2});
	std::vector<std::string> headerLine;

	std::string myFolderName = allFiles.path + allFiles.filesep + allFiles.positionNames[positionIn - 1];
	if (!std::filesystem::exists(myFolderName))std::filesystem::create_directories(myFolderName);
	std::string fileBase = myFolderName + allFiles.filesep;

	if (driftfile == "") {//Try to find the default drift file
		driftfile = fileBase + "Aligned_Drifts.csv";
	}
	if (std::filesystem::exists(driftfile)) {
		std::cout << "Importing Drifts from : " << driftfile << "\n";
		BLCSVIO::readCSV(driftfile, drifts, headerLine);
	}
	else std::cout << "WARNING : No drift file found. Assuming sample has no drift\n";
	if (drifts.size() < numOfFrame || drifts[0].size()!=2 ) {
		std::cout << "ERROR : There must be an x and y drift value for every frame. The drift file contains "<<drifts.size()<<" values but should contain "<< numOfFrame <<"\n";
		return 1;
	}
	
	if(numMontageImages == 0) {
		std::cout << "ERROR : The number of montage images cannot be zero\n";
		return 1;
	}
	
	if (measurementsfile == "") {//Try to find the default drift file
		measurementsfile = fileBase + "Detected_Filtered_Measurements.csv";
	}
	if (std::filesystem::exists(measurementsfile)) {
		std::cout << "Importing Measurement from : " << measurementsfile << "\n";
		if (BLCSVIO::readCSV(measurementsfile, measurements, headerLine) != 0)return 1;
	}
	else {
		std::cout << "Error : Measurements file not found so cannot extract particle positions.\n";
		return 1;
	}

	if (numOfChan > 1) {
		if (alignfile == "") {//Try to find the default drift file
			alignfile = fileBase + "Aligned_Channel_To_Channel_Alignment.csv";
		}
		if (std::filesystem::exists(alignfile)) {
			std::cout << "Importing Alignments from : " << alignfile << "\n";
			if (BLCSVIO::readCSV(alignfile, channelalignment, headerLine) != 0)return 1;
		}
		else {
			std::cout << "WARNING : No channel Alignments file found. Assuming sample is overlaid\n";
		}
		if (channelalignment.size() < numOfChan-1 || channelalignment[0].size() != 11) {
			std::cout << "ERROR : Invalid Channel Alignment File\n";
			return 1;
		}
	}

	if (BLCSVIO::readCSV(alignfile, channelalignment, headerLine) != 0)return 1;
	

	particle = std::max((size_t) 0, std::min(particle, measurements.size())); 
	size_t startFrameIn = startFrame < 0 ? numOfFrame + startFrame : startFrame - 1;
	size_t endFrameIn = endFrame < 0 ? numOfFrame + endFrame + 1 : endFrame;
	size_t NOFMeasure = endFrameIn > startFrameIn?endFrameIn - startFrameIn: 0;

	size_t delta = std::max(((int)(NOFMeasure / numMontageImages))-1, 1);
	size_t average = (delta - 1) / 2;

	//check values
	if(startFrameIn >= numOfFrame) {
		std::cout << "ERROR : Start frame ("<< startFrameIn+1 << ")is greater than images in stack ("<<numOfFrame<<")\n";
		return 1;
	}
	if (endFrameIn > numOfFrame) {
		endFrameIn = numOfFrame;
		std::cout << "End frame set to end of stack (" << numOfFrame << ")\n";
	}
	if(particle==0 || particle>measurements.size()) {
		std::cout << "ERROR : Particle number (" << particle << ") has to be between 1 and the number of detected particles  (" << measurements.size() << ")\n";
		return 1;
	}
	if(measurements[particle - 1].size()<18) {
		std::cout << "ERROR : measurements file must contain bounding box vlues in columns 15-18\n";
		return 1;
	}


	std::vector<float> image1(imagePoints), alignedimage(imagePoints, 0.0);

	uint32_t outputStart = (uint32_t)((measurements[particle - 1][14] - 3) + (measurements[particle - 1][16] - 3) * imageWidth);
	uint32_t outputWidth = (uint32_t)(measurements[particle - 1][15] - measurements[particle - 1][14] + 7);
	uint32_t outputHeight = (uint32_t)(measurements[particle - 1][17] - measurements[particle - 1][16] + 7);
	uint32_t outputImagePoints = outputWidth * outputHeight;
	uint32_t outputMontageWidth = (outputWidth + 2) * numMontageImages;
	uint32_t outputMontagePoints = (outputWidth + 2) * (outputHeight + 2) * numMontageImages * numOfChan;

	std::vector<float> montage(outputMontagePoints, 65000);

	//vector< vector<float>> avimageout( numOutputImages, vector<float>(outputImagePoints, 0.0));
	//vector<float> flattenedimout(outputImagePoints * numOutputImages, 0.0);


	std::vector<float> translated(imagePoints);
	int CountImAveraged;

	imageTransform_32f transformclass(imageWidth, imageHeight);
	std::vector<float> imagein(imagePoints), imaget(imagePoints), singleFrame(outputImagePoints);
	std::vector< std::vector<float> > outputImageStack(numMontageImages, std::vector<float>(outputImagePoints));

	BLTiffIO::TiffOutput* tiffout = NULL;

	//BLTiffIO::TiffOutput troubleshooting(outputfile + "troubleshooting.tiff", imageWidth, imageHeight, imageDepth, false);
	for (int chancount = 0; chancount < numOfChan; chancount++) {
		std::cout << "Starting Output for Channel " << std::to_string(chancount + 1) << "\n";

		if (bOutputImageStack) {
			std::string fileOutName = outputfile + "_Trace_" + std::to_string(particle) + "_Channel_" + std::to_string(chancount + 1) + ".tiff";
			std::cout << fileOutName << "\n";
			tiffout = new BLTiffIO::TiffOutput(fileOutName, outputWidth, outputHeight, imageDepth, false);
		}

		for (size_t imcount = 0; imcount < numMontageImages; imcount++) {
			std::vector<float> meanimage(imagePoints, 0.0);
			CountImAveraged = 0;
			for (int avcount = -1*(int)average; avcount <= average; avcount++) {
				int iminnum = startFrameIn + imcount * delta + avcount;
				if (iminnum >= 0 && iminnum < numOfFrame) {
					allFiles.read1dImage(positionIn - 1, iminnum, chancount, 0, imagein);

					if (chancount > 0) {
						//cout << channelalignment[chancount - 1][1] << " " << channelalignment[chancount - 1][2] << "\n";
						transformclass.transform(imagein, imaget, -channelalignment[chancount - 1][3], -channelalignment[chancount - 1][4], channelalignment[chancount - 1][1], channelalignment[chancount - 1][2]);
						imagein = imaget;
					}
					//cout << drifts[iminnum][0] << " " << drifts[iminnum][1] << "\n";
					transformclass.translate(imagein, imaget, -drifts[iminnum][0], -drifts[iminnum][1]);

					std::transform(imaget.begin(), imaget.end(), meanimage.begin(), meanimage.begin(), std::plus<float>());

					CountImAveraged++;
				}
			}
			if (CountImAveraged == 0)CountImAveraged = 1;
			std::transform(meanimage.begin(), meanimage.end(), meanimage.begin(), [CountImAveraged](auto x) { return x / CountImAveraged; });

			for (size_t i = 0; i < outputWidth; i++)for (size_t j = 0; j < outputHeight; j++) {
				uint32_t pos = outputStart + i + j * imageWidth;
				if (pos > 0 && pos < imagePoints) {
					outputImageStack[imcount][i + j * outputWidth] = meanimage[pos];
				}
			}

			//tiffout.write1dImage(outputImageStack[imcount]);
			//tiffout.write1dImage(meanimage);
		}


		//make the montage
		std::vector<float> flattenedimout;
		for (auto const& v : outputImageStack) {
			flattenedimout.insert(flattenedimout.end(), v.begin(), v.end());
		}
		std::sort(flattenedimout.begin(), flattenedimout.end());
		float mymin = flattenedimout[round(0.03 * outputImagePoints * numMontageImages)];
		float mymax = std::max(flattenedimout[round(0.97 * outputImagePoints * numMontageImages)], 1.001f*mymin);

		for (size_t imcount = 0; imcount < numMontageImages; imcount++)
			for (size_t i = 0; i < outputWidth; i++)for (size_t j = 0; j < outputHeight; j++) {
				uint16_t pos = (outputWidth + 2) * (outputHeight + 2) * numMontageImages * chancount;
				pos += (outputWidth + 2) * imcount + i + 1 + (j + 1) * outputMontageWidth;
				float toout = outputImageStack[imcount][i + j * outputWidth];
				montage[pos] = std::max(std::min(65000.0f * (toout - mymin) / (mymax - mymin), 65000.0f), 1.0f);
			}


		//output full stacks for particle

		for (size_t imcount = 0; imcount < numOfFrame; imcount++) {

			allFiles.read1dImage(positionIn - 1, imcount, chancount, 0, imagein);

			if (chancount > 0) {
				//cout << channelalignment[chancount - 1][1] << " " << channelalignment[chancount - 1][2] << "\n";
				transformclass.transform(imagein, imaget, -channelalignment[chancount - 1][3], -channelalignment[chancount - 1][4], channelalignment[chancount - 1][1], channelalignment[chancount - 1][2]);
				imagein = imaget;
			}
			//cout << drifts[iminnum][0] << " " << drifts[iminnum][1] << "\n";
			transformclass.translate(imagein, imaget, -drifts[imcount][0], -drifts[imcount][1]);

			for (size_t i = 0; i < outputWidth; i++)for (size_t j = 0; j < outputHeight; j++) {
				uint32_t pos = outputStart + i + j * imageWidth;
				if (pos > 0 && pos < imagePoints) {
					float toout = imaget[pos];
					singleFrame[i + j * outputWidth] = std::max(std::min(65000 * (toout - mymin) / (mymax - mymin), (float)65000), (float)1);
				}
			}

			if (bOutputImageStack && tiffout != NULL)tiffout->write1dImage(singleFrame);

		}

		if (bOutputImageStack && tiffout != NULL) delete tiffout;
	}

	BLTiffIO::TiffOutput(outputfile + "_Trace_" + std::to_string(particle) + "_Range_" + std::to_string(startFrameIn + 1) + "_" + std::to_string(delta) + "_" + std::to_string(endFrameIn) + "_montage.tiff", outputMontageWidth, (outputHeight + 2) * numOfChan, 16, false).write1dImage(montage);

	return 0;
}