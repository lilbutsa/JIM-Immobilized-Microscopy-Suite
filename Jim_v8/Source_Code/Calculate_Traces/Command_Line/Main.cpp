/*
 * Main.cpp - Calculate_Traces CLI
 *
 * Positional arguments:
 *   1) fileName         Input TIFF stack (or input base used by the processing pipeline)
 *   2) positionIn       Position index to process
 *   3) ROIfile          CSV of ROI pixel indices
 *   4) backgroundfile   CSV of background pixel indices
 *
 * Optional flags:
 *   -Start <int>                First frame to analyze (default: 1)
 *   -End <int>                  Last frame to analyze (default: all frames)
 *   -Drift <file>               Drift CSV file
 *   -Alignment <file>           Channel alignment CSV file
 *   -NumberOfChannels <int>     Number of channels if OME metadata is unavailable (default: 1)
 *   -FilesSplitByChannel        Input frame order is channel-blocked instead of interleaved
 *   -Output <string>            Output base name override
 */

#include <string>
#include <iostream>
#include <vector>
#include "BLFlagParser.h"

int Calculate_Traces(std::string fileName, size_t positionIn, std::string ROIfile, std::string backgroundfile, int startFrame = 1, int endFrame = -1, std::string driftfile = "", std::string alignfile = "", std::string outputFileBase = "", int numOfChannels = 1, bool filesSplitByChannelIn = false);

int main(int argc, char *argv[])
{
	if (argc == 1 || (std::string(argv[1]).substr(0, 2) == "-h" || std::string(argv[1]).substr(0, 2) == "-H")) {
		std::cout << "Usage: Calculate_Traces <fileName> <positionIn> <ROIfile> <backgroundfile> [options]\n";
		std::cout << "Options:\n";
		std::cout << "-Start i (Default i = 1) Specify first frame to analyze.\n";
		std::cout << "-End i (Default i = total number of frames) Specify last frame to analyze.\n";
		std::cout << "-Drift <file> CSV file containing XY drift per frame.\n";
		std::cout << "-Alignment <file> CSV file containing channel alignment parameters.\n";
		std::cout << "-NumberOfChannels i (Default i = 1) Set channel count when metadata is unavailable.\n";
		std::cout << "-FilesSplitByChannel Input frames are ordered by channel blocks.\n";
		std::cout << "-Output <name> Override output base name.\n";
		return 0;
	}
	if (argc < 5) {
		std::cout << "Insufficient arguments.\n";
		std::cout << "Usage: Calculate_Traces <fileName> <positionIn> <ROIfile> <backgroundfile> [options]\n";
		return 1;
	}
	std::string inputfile = argv[1];
	size_t positionIn = std::stoi(argv[2]);
	std::string ROIfile = argv[3];
	std::string backgroundfile = argv[4];

	std::string outputfile = "", driftfile = "", alignfile = "";
	int start = 1, end = -1, numOfChannels=1;
	bool splitByChannel = false;

	std::vector<std::pair<std::string, int*>> intFlags = { {"Start", &start},{"End", &end},{"NumberOfChannels", &numOfChannels} };
	std::vector<std::pair<std::string, bool*>> boolFlags = {{"FilesSplitByChannel", &splitByChannel} };
	std::vector<std::pair<std::string, std::string*>> stringFlags = { {"Drift", &driftfile},{"Alignment", &alignfile},{"Output", &outputfile} };

	if (BLFlagParser::parseValues(stringFlags, argc, argv)) return 1;
	if (BLFlagParser::parseValues(intFlags, argc, argv)) return 1;
	if (BLFlagParser::parseValues(boolFlags, argc, argv)) return 1;


	return Calculate_Traces(inputfile, positionIn, ROIfile, backgroundfile, start, end, driftfile, alignfile, outputfile, numOfChannels, splitByChannel);
}
