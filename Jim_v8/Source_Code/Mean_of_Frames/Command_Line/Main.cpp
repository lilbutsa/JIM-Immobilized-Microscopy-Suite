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
 *   argv[1] - fileName input (TIFF stack or input base used by the processing pipeline).
 *
 * Optional Flags:
 *   -Position <int>            : Position index to process (default: 0)
 *   -Start <val1 val2 ...>     : Start frame per channel (default: 1)
 *   -End <val1 val2 ...>       : End frame per channel (default: all frames)
 *   -MaxProjection <v1 v2 ...> : Per-channel projection mode (0 = mean/sum, non-zero = max)
 *   -Weights <w1 w2 ...>       : Scaling weights per channel
 *   -NoNorm                    : Skip normalization (output raw summed intensity values)
 *   -Drift <file>              : Drift CSV file
 *   -Alignment <file>          : Channel alignment CSV file
 *   -Output <string>           : Output file base override
 *
 * Output:
 *   - <outputfile>_Partial_Mean.tiff : Composite image result.
 *       If normalization is used, written as 16-bit TIFF.
 *       If not normalized, written as 32-bit float TIFF.
 *
 * Notes:
 *   - Channel alignment is only applied if multiple channels are present.
 *   - Drift correction is applied before frame aggregation.
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
#include "BLFlagParser.h"

int Mean_of_Frames(std::string fileName, size_t positionIn, std::vector<int> start, std::vector<int> end, std::vector<int> bvMaxProject, std::vector<float> weights, bool bNormalize, std::string driftfile = "", std::string alignfile = "", std::string outputFileName = "Image_For_Detection_Partial_Mean");


// Positional input is fileName; all other inputs are optional flags parsed below.
int main(int argc, char *argv[])
{


	if (argc == 1 || (std::string(argv[1]).substr(0, 2) == "-h" || std::string(argv[1]).substr(0, 2) == "-H")) {
		std::cout << "Usage: Mean_of_Frames <fileName> [options]\n";
		std::cout << "Options:\n";
		std::cout << "-Position i (Default i = 0) Position index to process.\n";
		std::cout << "-Start v1 v2 ... Start frame per channel.\n";
		std::cout << "-End v1 v2 ... End frame per channel.\n";
		std::cout << "-MaxProjection v1 v2 ... Per-channel projection mode (0 = mean, non-zero = max).\n";
		std::cout << "-Weights w1 w2 ... Per-channel weights.\n";
		std::cout << "-NoNorm Disable normalization.\n";
		std::cout << "-Drift <file> Drift CSV file.\n";
		std::cout << "-Alignment <file> Channel alignment CSV file.\n";
		std::cout << "-Output <name> Override output base name.\n";
		return 0;
	}

	if (argc < 2) {
		std::cout << "Insufficient arguments.\n";
		std::cout << "Usage: Mean_of_Frames <fileName> [options]\n";
		return 1;
	}
	std::string fileName = argv[1];

	int position=0;
	std::vector<int> start, end, bvMaxProject;
	std::vector<float>weights;
	bool bSkipNormalization = false;
	std::string driftfile = "", alignfile = "", outputfile="";

	std::vector<std::pair<std::string, std::vector<int>*>> vecIntFlags = { {"Start", &start},{"End", &end}, { "MaxProjection",& bvMaxProject } };
	std::vector<std::pair<std::string, std::vector<float>*>> vecFloatFlags = { {"Weights", &weights} };
	std::vector<std::pair<std::string, bool*>> boolFlags = { {"NoNorm", &bSkipNormalization} };
	std::vector<std::pair<std::string, int*>> intFlags = { {"Position", &position} };
	std::vector<std::pair<std::string, std::string*>> stringFlags = { {"Drift", &driftfile},{"Alignment", &alignfile},{"Output", &outputfile} };


	if (BLFlagParser::parseValues(vecIntFlags, argc, argv)) return 1;
	if (BLFlagParser::parseValues(vecFloatFlags, argc, argv)) return 1;
	if (BLFlagParser::parseValues(boolFlags, argc, argv)) return 1;
	if (BLFlagParser::parseValues(intFlags, argc, argv)) return 1;
	if (BLFlagParser::parseValues(stringFlags, argc, argv)) return 1;

	return Mean_of_Frames(fileName, position, start, end, bvMaxProject, weights, !bSkipNormalization, driftfile, alignfile, outputfile);
	
	//system("PAUSE");

}
