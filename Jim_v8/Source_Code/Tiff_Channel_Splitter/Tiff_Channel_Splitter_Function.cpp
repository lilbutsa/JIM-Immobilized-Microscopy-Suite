#include <string>
#include <iostream>
#include <vector>
#include "BLTiffIO.h"
#include <algorithm>
#include <filesystem>
#include <math.h>
#include <stdint.h>



void getStackOrder(std::vector<BLTiffIO::TiffInput*>& vis, std::vector<std::vector<std::vector<int>>>& stackorderout);
void vertFlipImage(std::vector< std::vector<uint16_t>>& imageio);
void horzFlipImage(std::vector< std::vector<uint16_t>>& imageio);
void rotateImage(std::vector< std::vector<uint16_t>>& imageio, int angle);


int Tiff_Channel_Splitter(std::string inputfile,  std::vector<std::vector<int>>& orientation, bool bmetadata, int numOfChan, bool bAcrossMultifiles) {

	size_t imageWidth, imageHeight, imageDepth;
	std::vector<std::vector<uint16_t>> image;


	BLTiffIO::MultiTiffInput mymulti(inputfile, bmetadata, bAcrossMultifiles,numOfChan);
	
	for (size_t posCount = 0; posCount < mymulti.maxPos; posCount++) {
		std::string myFolderName = mymulti.path + mymulti.filesep + mymulti.positionNames[posCount];
		if(!std::filesystem::exists(myFolderName))std::filesystem::create_directories(myFolderName);
		for (size_t chanCount = 0; chanCount < mymulti.maxChan; chanCount++) {
			std::string outputfilename = myFolderName+ mymulti.filesep+ "Raw_Image_Stack_Channel_" + std::to_string(chanCount + 1) + ".tif";
			std::cout << "Writing : " << outputfilename << "\n";
			if (mymulti.imageInfo(posCount, 0, chanCount, 0, imageWidth, imageHeight, imageDepth) == 0) {//check if the channel exists
				BLTiffIO::TiffOutput outputFile(outputfilename, imageWidth, imageHeight, imageDepth, true);
				for (size_t frameCount = 0; frameCount < mymulti.maxFrame; frameCount++) {
					if (mymulti.read2dImage(posCount, frameCount, chanCount, 0, image) == 0) {//check the image exists
						if(orientation.size()>chanCount && orientation[chanCount][0]==1)vertFlipImage(image);
						if (orientation.size() > chanCount && orientation[chanCount][1] == 1)vertFlipImage(image);
						if (orientation.size() > chanCount && orientation[chanCount][2] != 0)rotateImage(image, orientation[chanCount][2]);
						outputFile.write2dImage(image);
					}
				}
			}
		}
	}

	return 0;
}
