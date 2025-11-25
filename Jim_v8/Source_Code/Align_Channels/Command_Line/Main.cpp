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

int Align_Channels(std::string fileBase, std::vector<std::string>& inputfiles, int startFrame, int endFrame, std::vector<std::vector<float>>& alignments, bool skipIndependentDrifts, double maxShift, bool outputAligned);


int main(int argc, char *argv[])
{

	if (argc == 1 || (std::string(argv[1]).substr(0, 2) == "-h" || std::string(argv[1]).substr(0, 2) == "-H")) {
		std::cout << "Standard input: [Output File Base] [Input Image Stack Channel 1]... Options\n";
		std::cout << "Options:\n";
		std::cout << "-Start i (Default i = 1) Specify frame i initially align from\n";
		std::cout << "-End i (Default i = total number of frames) Specify frame i to initially align to\n";
		std::cout << "-MaxShift i (Default i = unlimited) The maximum amount of drift in x and y that will be searched for during alignment\n";
		std::cout << "-OutputAligned (Default false) Save the aligned image stacks\n";
		std::cout << "-SkipIndependentDrifts (Default false) Only Generate combined drifts, For Channel to Channel alignment use the reference frames\n";
		std::cout << "-Alignment Manually input the alignment between channels. Requires 4 values per extra channel (x offset ch2, ch2... yoffset ch2 ch3..., rotation ch2 ch3... scale ch2 ch3...)\n";
		return 0;
	}


	std::string fileBase;
	int numInputFiles = 0;
	std::vector<BLTiffIO::TiffInput*> is;//input stack
	bool inputalignment = false,skipIndependentDrifts = false;
	uint32_t start = 0, end = 1000000000;
	std::vector<std::vector<float>> alignments;
	std::vector<std::vector<float>> drifts;
	float maxShift = FLT_MAX;
	bool outputAligned = false;



	if (argc < 3)throw std::invalid_argument("Insufficient Arguments");
	fileBase = std::string(argv[1]);

	for (int i = 2; i < argc && std::string(argv[i]).substr(0, 1) != "-"; i++) numInputFiles++;
	if (numInputFiles == 0)throw std::invalid_argument("No Input Image Stacks Detected");
	std::vector<std::string> inputfiles(numInputFiles);
	for (int i = 0; i < numInputFiles; i++)inputfiles[i] = argv[i + 4];

	alignments = std::vector<std::vector<float>>(numInputFiles-1, {0,0,0,1});
	std::vector<float> alignmentArguments;

	std::vector<std::pair<std::string, uint32_t*>> intFlags = {{"Start", &start},{"End", &end}};
	std::vector<std::pair<std::string, float*>> floatFlags = {{"MaxShift", &maxShift} };
	std::vector<std::pair<std::string, bool*>> boolFlags = { {"OutputAligned", &outputAligned}, {"SkipIndependentDrifts", &skipIndependentDrifts} };
	std::vector<std::pair<std::string, std::vector<float>*>> vecFlags = { {"Alignment", &alignmentArguments} };

	if (BLFlagParser::parseValues(intFlags, argc, argv)) return 1;
	if (BLFlagParser::parseValues(floatFlags, argc, argv)) return 1;
	if (BLFlagParser::parseValues(boolFlags, argc, argv)) return 1;
	if (BLFlagParser::parseValues(vecFlags, argc, argv)) return 1;


	if (alignmentArguments.size()>0 && alignmentArguments.size() < 4 * (numInputFiles - 1))throw std::invalid_argument("Not Enough Alignment Inputs.\nRequires 4 values per extra channel (x offset ch2 ch2... yoffset ch2 ch3..., rotation ch2 ch3... scale ch2 ch3...)\n");
	if (alignmentArguments.size() >= 4 * (numInputFiles - 1)) {
		inputalignment = true;
		for (int j = 0; j < 4; j++)for (int k = 0; k < numInputFiles - 1; k++)alignments[k][j] = alignmentArguments[k + j * (numInputFiles - 1)];
	}

	return Align_Channels(fileBase, inputfiles, start, end, alignments, skipIndependentDrifts, maxShift, outputAligned);



	//system("PAUSE");
	



}