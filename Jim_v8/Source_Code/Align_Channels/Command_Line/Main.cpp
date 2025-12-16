/**
 * @file Align_Channels Main.cpp 
 * @brief Multi-channel image stack drift correction and alignment pipeline.
 *
 * This program performs sub-pixel drift correction and inter-channel alignment
 * of multi-frame TIFF image stacks. It supports automatic alignment estimation
 * or manual input, and can optionally output aligned image stacks.
 *
 * Usage:
 *   ./Align_Channels [OutputFileBase] [Channel1.tif] [Channel2.tif] ... [options]
 *
 * Dependencies:
 *   - BLTiffIO (for TIFF reading/writing)
 *   - BLImageTransform (for image transformations and alignment)
 *   - BLFlagParser (for parsing command-line arguments)
 *
 * Author: James Walsh
 * Date: July 2020
 */



#include "BLTiffIO.h"
#include "BLImageTransform.h"
#include "BLFlagParser.h"
#include <stdexcept> 

int Align_Channels(std::string fileName, int startFrame, int endFrame, size_t positionIn, std::vector<std::vector<float>>& alignments, bool skipIndependentDrifts, float maxShift, bool outputAligned);


int main(int argc, char *argv[])
{

	if (argc == 1 || (std::string(argv[1]).substr(0, 2) == "-h" || std::string(argv[1]).substr(0, 2) == "-H")) {
		std::cout << "Standard input: FileName... Options\n";
		std::cout << "Options:\n";
		std::cout << "-Start i (Default i = 1) Specify frame i initially align from\n";
		std::cout << "-End i (Default i = total number of frames) Specify frame i to initially align to\n";
		std::cout << "-Position i (Default i = 0 (all)) Specify position to analyse, setting to 0 analyzes all positions \n";
		std::cout << "-MaxShift i (Default i = unlimited) The maximum amount of drift in x and y that will be searched for during alignment\n";
		std::cout << "-OutputAligned (Default false) Save the aligned image stacks\n";
		std::cout << "-SkipIndependentDrifts (Default false) Only Generate combined drifts, For Channel to Channel alignment use the reference frames\n";
		std::cout << "-Alignment Manually input the alignment between channels. Requires 4 values per extra channel (x offset ch2, ch2... yoffset ch2 ch3..., rotation ch2 ch3... scale ch2 ch3...)\n";
		return 0;
	}


	int numInputFiles = 0;
	std::vector<BLTiffIO::TiffInput*> is;//input stack
	bool inputalignment = false,skipIndependentDrifts = false;
	int start = 1, end = -1, position = 0;
	std::vector<std::vector<float>> alignments;
	std::vector<std::vector<float>> drifts;
	float maxShift = FLT_MAX;
	bool outputAligned = false;


	std::string fileName = std::string(argv[1]);



	alignments = std::vector<std::vector<float>>();
	std::vector<float> alignmentArguments;

	std::vector<std::pair<std::string, int*>> intFlags = {{"Start", &start},{"End", &end},{"Position", &position} };
	std::vector<std::pair<std::string, float*>> floatFlags = {{"MaxShift", &maxShift} };
	std::vector<std::pair<std::string, bool*>> boolFlags = { {"OutputAligned", &outputAligned}, {"SkipIndependentDrifts", &skipIndependentDrifts} };
	std::vector<std::pair<std::string, std::vector<float>*>> vecFlags = { {"Alignment", &alignmentArguments} };

	if (BLFlagParser::parseValues(intFlags, argc, argv)) return 1;
	if (BLFlagParser::parseValues(floatFlags, argc, argv)) return 1;
	if (BLFlagParser::parseValues(boolFlags, argc, argv)) return 1;
	if (BLFlagParser::parseValues(vecFlags, argc, argv)) return 1;


	if (alignmentArguments.size()>0 && alignmentArguments.size() % 4 != 0 )throw std::invalid_argument("Not Enough Alignment Inputs.\nRequires 4 values per extra channel (x offset ch2 ch2... yoffset ch2 ch3..., rotation ch2 ch3... scale ch2 ch3...)\n");
	if (alignmentArguments.size() >0) {
		alignments = std::vector<std::vector<float>>(alignmentArguments.size()/4, std::vector<float>(4, 0.0f));
		for (size_t i = 0; i < alignments.size(); i++)for (size_t j = 0; j < 4; j++)alignments[i][j] = alignmentArguments[j + i * 4];
	}

	return Align_Channels(fileName, start, end, position, alignments, skipIndependentDrifts, maxShift, outputAligned);



	//system("PAUSE");
	



}