/*
 * Main.cpp - Isolate_Particle
 *
 * Description:
 *   This program creates a montage of a single particle's. It outputs an intensity-normalized montage 
 *   and optionally a TIFF stack of isolated regions-of-interest (ROIs) for the specified particle.
 *
 *
 * Core Functionality:
 *   - Loads image stacks, channel alignment matrices, drift correction data, and particle bounding boxes.
 *   - Applies spatial transformation (translation, affine alignment) to each frame.
 *   - Averages over specified frame ranges around each step to reduce noise.
 *   - Extracts and crops a bounding box around the particle, and assembles a montage.
 *   - Optionally outputs the time series of cropped images as a TIFF stack.
 *
 * Input Arguments (Positional):
 *   argv[1]  - fileName input (TIFF stack or input base used by the processing pipeline)
 *   argv[2]  - position index to process
 *   argv[3]  - particle index to isolate
 *
 * Optional Flags:
 *   -Start <int>      : First frame to include (default = 1)
 *   -End <int>        : Last frame to include (default = all frames)
 *   -MontageImages <int> : Number of images shown in montage output (default = 10)
 *   -OutputImageStack : Output a full aligned ROI stack as a TIFF
 *   -Drift <file>     : Drift CSV file
 *   -Alignment <file> : Channel alignment CSV file
 *   -Measurement <file> : ROI measurement CSV file
 *   -Output <name>    : Output base name override
 *
 * Output Files:
 *   - <base>_Trace_<particle>_Range_<start>_<delta>_<end>_montage.tiff:
 *       A montage image of the aligned ROI over time (channels stacked vertically).
 *   - <base>_Trace_<particle>_Channel_<N>.tiff (optional):
 *       A TIFF stack of aligned ROI frames for channel N (only if -OutputImageStack is specified).
 *
 * Notes:
 *   - Pixel values are normalized using the 3rd to 97th percentile across all output frames for consistent contrast.
 *   - Alignment and drift correction are applied before cropping.
 *   - Output montage adds a 1-pixel border between tiles.
 *
 * Dependencies:
 *   - BLCSVIO: CSV file reader for measurement/alignment input.
 *   - BLTiffIO: TIFF I/O wrapper for reading multi-frame images and writing output.
 *   - BLImageTransform: Provides affine and translation operations on images.
 *   - BLFlagParser: Lightweight CLI flag parser.
 *
 * @author James Walsh james.walsh@phys.unsw.edu.au
 * @date 2025-07-14
 */


#include <string>
#include <iostream>
#include <vector>
#include <algorithm>
#include "BLFlagParser.h"



int Isolate_Particle(std::string fileName, size_t positionIn, size_t particle, int startFrame = 1, int endFrame = -1, size_t numMontageImages = 10, bool bOutputImageStack = false, size_t numOfChannels = 1, bool filesSplitByChannelIn = false, std::string driftfile = "", std::string alignfile = "", std::string measurementsfile = "", std::string outputfile = "");
	// Positional inputs are fileName, positionIn, and particle; all others are optional flags.
int main(int argc, char* argv[])
{

	if (argc == 1 || (std::string(argv[1]).substr(0, 2) == "-h" || std::string(argv[1]).substr(0, 2) == "-H")) {
		std::cout<<"Usage: Isolate_Particle <fileName> <positionIn> <particle> [options]\n";
		std::cout << "Options:\n";
		std::cout << "-MontageImages i (Default i = 10) Number of images for the montage\n";
		std::cout << "-Start i (Default i = 1) Specify frame i to start isolating from\n";
		std::cout << "-End i (Default i = total number of frames) Specify frame i to end isolating from\n";
		std::cout << "-OutputImageStack : Output the ROI for the particle as a tiff stack \n";
		std::cout << "-NumberOfChannels i (Default i = 1) Sets the number of channels to split the file into. Only used if no OME metadata is present. \n";
		std::cout << "-FilesSplitByChannel : Images ordered by channel rather than alternating. Only used if no OME metadata is present. \n";
		std::cout << "-Alignment <file>  : CSV file containing Channel to channel alignment parameters for multi-channel output.\n";
		std::cout << "-Measurement <file>  : CSV file containing the ROI measurements.\n";
		std::cout << "-Drift <file>  : CSV file containing the XY drifts for each frame for Channel 1.\n";
		std::cout << "-Output <name>  : Change the output file base name.\n";
		return 0;
	}


	int position, particle, start = 1, end = -1, montageImages = 10, numOfChannels = 1;
	
	std::string fileName, outputfile="",driftfile="",alignfile="", measurementsfile="";
	bool bOutputImageStack = false, splitByChannel = false;

	try {
		if (argc<4)throw std::invalid_argument("Insufficient Arguments");
		fileName = argv[1];
		position = std::stoi(argv[2]);
		particle = std::stoi(argv[3]);


		std::vector<std::pair<std::string, int*>> intFlags = {{"Start", &start},{"End", &end},{"MontageImages", &montageImages},{"NumberOfChannels", &numOfChannels} };
		std::vector<std::pair<std::string, bool*>> boolFlags = { {"OutputImageStack", &bOutputImageStack}, {"FilesSplitByChannel", &splitByChannel} };
		std::vector<std::pair<std::string, std::string*>> stringFlags = { {"Drift", &driftfile},{"Alignment", &alignfile},{"Measurement", &measurementsfile},{"Output", &outputfile} };

		if (BLFlagParser::parseValues(stringFlags, argc, argv)) return 1;
		if (BLFlagParser::parseValues(intFlags, argc, argv)) return 1;
		if (BLFlagParser::parseValues(boolFlags, argc, argv)) return 1;

		return Isolate_Particle(fileName, position, particle, start, end, montageImages, bOutputImageStack, numOfChannels, splitByChannel, driftfile, alignfile, measurementsfile, outputfile);


	}
	catch (const std::invalid_argument & e) {
		std::cout << "Error Inputting Parameters\n";
		std::cout << e.what() << "\n";
		std::cout << "See -Help for help\n";
		return 1;
	}

	


	return 0;
}
