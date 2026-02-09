/*
 * Main.cpp - Mean_of_Frames
 *
 * Description:
 *   This program generates a combined reference image from a range of frames across multiple imaging channels.
 *   It applies drift correction, channel alignment, and optional normalization.
 *   The resulting image is typically used for particle detection or as a composite visual reference.
 *
 * Core Functionality:
 *   - Reads multi-frame TIFF images for each input channel.
 *   - Applies spatial drift correction to each frame.
 *   - Applies affine transformations to align channels using alignment CSV data.
 *   - Computes either a mean or maximum projection over specified frame ranges.
 *   - Allows optional intensity weighting for each channel.
 *   - Optionally normalizes the result across time and channels.
 *   - Outputs the final image as a TIFF file.
 *
 * Input Arguments (Positional):
 *   argv[1] - Channel alignment CSV file (can be empty for single-channel input).
 *   argv[2] - Drift correction CSV file (x, y drift per frame).
 *   argv[3] - Output file base name.
 *   argv[4...] - Input TIFF stacks (one per imaging channel).
 *
 * Optional Flags:
 *   -Start <val1 val2 ...>    : Start frame per channel (1-based, default = 1).
 *                               Can also be negative (offset from end) or used with -Percent.
 *   -End <val1 val2 ...>      : End frame per channel (inclusive, default = total frames).
 *                               Can also be negative or percent-based.
 *   -Percent                  : Treat -Start and -End values as percentages (0–100).
 *   -Weights <w1 w2 ...>      : Scaling weights per channel.
 *   -MaxProjection            : Use max projection instead of summation/mean across frames. Gove a 0 for mean or 1 use Max projection for each channel eg. -MaxProjection 0 1 0 uses max project for channel 2
 *   -NoNorm                   : Skip normalization (output raw summed intensity values).
 *
 * Output:
 *   - <outputfile>_Partial_Mean.tiff : Composite image result.
 *       If normalization is used, written as 16-bit TIFF.
 *       If not normalized, written as 32-bit float TIFF.
 *
 * Notes:
 *   - Channel alignment is only applied if multiple input files are given.
 *   - Drift correction is always applied prior to averaging.
 *   - Frame ranges and weights are flexible and user-defined per channel.
 *   - Designed for preprocessing steps in single-particle or ROI analysis workflows.
 *
 * Dependencies:
 *   - BLCSVIO: Reads CSV files (drift, alignment).
 *   - BLTiffIO: Reads and writes multi-frame TIFF stacks.
 *   - BLImageTransform: Provides drift and affine transformation utilities.
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

int Mean_of_Frames(std::string fileName, int positionIn, std::vector<int> start, std::vector<int> end, std::vector<int> bvMaxProject, std::vector<float> weights, bool bNormalize, std::string driftfile = "", std::string alignfile = "");


//Input should be align file, drift file, outfile, all image files, -Start chan1 chan2...,-End chan1, chan2
int main(int argc, char *argv[])
{


	if (argc < 1) { std::cout << "could not read file name.\n"; return 1; }
	std::string fileName = argv[1];

	int position=0;
	std::vector<int> start, end, bvMaxProject;
	std::vector<float>weights;
	bool bSkipNormalization = false;
	std::string driftfile = "", alignfile = "";

	std::vector<std::pair<std::string, std::vector<int>*>> vecIntFlags = { {"Start", &start},{"End", &end}, { "MaxProjection",& bvMaxProject } };
	std::vector<std::pair<std::string, std::vector<float>*>> vecFloatFlags = { {"Weights", &weights} };
	std::vector<std::pair<std::string, bool*>> boolFlags = { {"NoNorm", &bSkipNormalization} };
	std::vector<std::pair<std::string, int*>> intFlags = { {"Position", &position} };
	std::vector<std::pair<std::string, std::string*>> stringFlags = { {"Drift", &driftfile},{"Alignment", &alignfile} };

	if (BLFlagParser::parseValues(vecIntFlags, argc, argv)) return 1;
	if (BLFlagParser::parseValues(vecFloatFlags, argc, argv)) return 1;
	if (BLFlagParser::parseValues(boolFlags, argc, argv)) return 1;
	if (BLFlagParser::parseValues(intFlags, argc, argv)) return 1;
	if (BLFlagParser::parseValues(stringFlags, argc, argv)) return 1;

	return Mean_of_Frames(fileName, position, start, end, bvMaxProject, weights, !bSkipNormalization, driftfile, alignfile);
	
	//system("PAUSE");

}