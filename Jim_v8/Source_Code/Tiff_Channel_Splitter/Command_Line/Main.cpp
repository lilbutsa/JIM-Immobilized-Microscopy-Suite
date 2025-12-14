#include <string>
#include <iostream>
#include <vector>
#include "BLTiffIO.h"
#include "BLFlagParser.h"


int Tiff_Channel_Splitter(std::string inputfile, std::vector<std::vector<int>>& tranformations, bool bmetadata, int numOfChan, bool bAcrossMultifiles);

int main(int argc, char* argv[])
{


	if (argc == 1 || (std::string(argv[1]).substr(0, 2) == "-h" || std::string(argv[1]).substr(0, 2) == "-H")) {
		std::cout << "Standard input: [Input Image Stack file 1] Options\n";
		std::cout << "Options:\n";
		std::cout << "-Transform [Vertical Flip each channel (0 = no, 1 = yes)] [Horizontal Flip each channel (0 = no, 1 = yes)] [Rotate each channel clockwise (0, 90, 180 or 270)] provide a value for each channel\n";
		std::cout << "-NumberOfChannels i (Default i = 2) Sets the number of channels to split the file into. Only used if no OME metadata is present. \n";
		std::cout << "-DisableMetadata Ignore OME metadata. Use if stack has been altered but meta data has not.\n";
		std::cout << "-AcrossMultifiles For data with no metadata and data is split across multiple files. i.e. Combine all files in the folder into a single dataset. Files need to be in alphabetical order\n";
		return 0;
	}

	std::string fileBase = std::string(argv[1]);

	int numOfChan = 2;
	bool bmetadata = true;
	bool bAcrossMultifiles = true;

	std::vector<int> tranformationsArgs;
	std::vector< std::vector<int>> tranformations;

	std::vector<std::pair<std::string, int*>> intFlags = {{"NumberOfChannels", &numOfChan}};
	std::vector<std::pair<std::string, bool*>> boolFlags = { {"DisableMetadata", &bmetadata}, {"AcrossMultifiles", &bAcrossMultifiles} };
	std::vector<std::pair<std::string, std::vector<int>*>> vecFlags = { {"Transform", &tranformationsArgs} };

	if (BLFlagParser::parseValues(intFlags, argc, argv)) return 1;
	if (BLFlagParser::parseValues(boolFlags, argc, argv)) return 1;
	if (BLFlagParser::parseValues(vecFlags, argc, argv)) return 1;

	//Convert transformations to 2Darray

	if (tranformationsArgs.size() % 3 != 0) {
		std::cout << "Error : Invalid Number of transform parameters.\n Three parameters required per channel:\n[Vertical Flip each channel (0 = no, 1 = yes)] [Horizontal Flip each channel (0 = no, 1 = yes)] [Rotate each channel clockwise (0, 90, 180 or 270)]\n";
		return 1;
	}

	if (tranformationsArgs.size() > 0) {
		std::vector< std::vector<int>> tranformationsIn(tranformationsArgs.size() / 3, std::vector<int>(3, 0));
		for (size_t j = 0; j < tranformationsArgs.size(); j++)tranformationsIn[j / 3][j % 3] = tranformationsArgs[j];
		tranformations = tranformationsIn;

		for (size_t j = 0; j < tranformations.size(); j++) {
			if (tranformations[j][1] == 1)std::cout << " Flipping Channel "<<j+1<<" Vertically ";
			if (tranformations[j][2] == 1)std::cout << " Flipping  Channel " << j + 1 << " Horizontally";
			if (tranformations[j][3] > 1)std::cout << " Rotating  Channel " << j + 1 << " by " << tranformations[j][3] << " Degrees";
		}
	}
	
	return Tiff_Channel_Splitter(fileBase, tranformations, bmetadata, numOfChan, bAcrossMultifiles);

}











