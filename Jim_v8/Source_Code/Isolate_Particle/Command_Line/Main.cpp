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
 *   argv[1]  - Channel alignment CSV file (ignored if only one channel).
 *   argv[2]  - Drift correction CSV file (x, y drift per frame).
 *   argv[3]  - Particle measurement CSV file (bounding box metadata).
 *   argv[4]  - Output filename base (used for all output TIFFs).
 *   argv[5...] - One or more TIFF stacks (1 per channel, all same dimensions).
 *
 * Optional Flags:
 *   -Particle <int>   : Index of particle to isolate (1-based, default = 1)
 *   -Start <int>      : First frame to include (0-based, default = 0)
 *   -End <int>        : Last frame to include (exclusive, default = total number of frames)
 *   -Delta <int>      : Frame step between montage entries (default = 1)
 *   -Average <int>    : Number of frames to average around each montage frame (must be odd, default = 1)
 *   -OutputImageStack : Output a full aligned ROI stack as a TIFF
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
#include "BLTiffIO.h"
#include "BLImageTransform.h"
#include "BLCSVIO.h"
#include "BLFlagParser.h"



int Isolate_Particle(std::string outputfile, std::vector<std::string> inputfiles, std::string driftfile, std::string alignfile, std::string measurementsfile, int particle, int start, int end, int delta, int average, bool bOutputImageStack);

//Input should be align file, drift file, outfile, all image files, -Start chan1 chan2...,-End chan1, chan2
int main(int argc, char* argv[])
{


	if (argc == 1 || (std::string(argv[1]).substr(0, 2) == "-h" || std::string(argv[1]).substr(0, 2) == "-H")) {
		std::cout<<"Standard input: [channel alignment file] [Drift Correction File] [Particle Measurements File] [Output File Base] [Input Image Stack Channel 1]... Options\n";
		std::cout << "Options:\n";
		std::cout << "-Particle i (Default i = 1) Specify particle i to isolate\n";
		std::cout << "-Start i (Default i = 1) Specify frame i to start isolating from\n";
		std::cout << "-End i (Default i = total number of frames) Specify frame i to end isolating from\n";
		std::cout << "-Delta i (Default i = 1) Specify steps in frames between isolated images\n";
		std::cout << "-Average i (Default i = 1) Specify number of frames around each step to average image (Must Be Odd)\n";
		std::cout << "-outputImageStack Output the ROI for the particle as a tiff stack \n";
		return 0;
	}

	int numInputFiles = 0;
	int particle = 1, start = 0, end = 100000000, delta = 1, average = 1;
	
	std::string outputfile,driftfile,alignfile, measurementsfile;
	std::vector<BLTiffIO::TiffInput*> vcinput;
	bool bOutputImageStack = false;

	try {
		if (argc<5)throw std::invalid_argument("Insufficient Arguments");
		for (int i = 5; i < argc && std::string(argv[i]).substr(0, 1) != "-"; i++) numInputFiles++;
		if(numInputFiles == 0)throw std::invalid_argument("No Input Image Stacks Detected");


		std::vector<std::string> inputfiles(numInputFiles);
		for (int i = 0; i < numInputFiles; i++)inputfiles[i] = argv[i + 5];

		std::vector<std::pair<std::string, int*>> intFlags = { {"Particle", &particle},{"Start", &start},{"End", &end},{"Delta", &delta},{"Average", &average} };
		std::vector<std::pair<std::string, bool*>> boolFlags = { {"OutputAligned", &bOutputImageStack} };

		if (BLFlagParser::parseValues(intFlags, argc, argv)) return 1;
		if (BLFlagParser::parseValues(boolFlags, argc, argv)) return 1;

		if (average % 2 == 0)throw std::invalid_argument("Averaging Value Must Be Odd");

		alignfile = argv[1];
		driftfile = argv[2];
		measurementsfile = argv[3];
		outputfile = argv[4];

		Isolate_Particle(outputfile, inputfiles, driftfile, alignfile, measurementsfile, particle, start, end, delta, average, bOutputImageStack);

	}
	catch (const std::invalid_argument & e) {
		std::cout << "Error Inputting Parameters\n";
		std::cout << e.what() << "\n";
		std::cout << "See -Help for help\n";
		return 1;
	}

	


	return 0;
}