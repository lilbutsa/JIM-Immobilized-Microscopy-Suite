/**
 * @file Main.cpp
 * @brief CLI entry point for Align_Channels.
 *
 * Positional arguments:
 *   1) fileName : Input TIFF stack (or input base used by the processing pipeline).
 *
 * Optional flags:
 *   -Start <int>                  First frame to use for alignment (default: 1)
 *   -End <int>                    Last frame to use (default: all frames)
 *   -Position <int>               Position index to process; 0 processes all positions (default: 0)
 *   -MaxShift <float>             Maximum absolute XY shift searched during alignment (default: unlimited)
 *   -OutputAligned                Write aligned TIFF stack outputs
 *   -SkipIndependentDrifts        Skip per-channel independent drift fitting
 *   -Alignment <v1 ... v4N>       Manual channel alignment values; 4 values per extra channel
 *                                 (x offset, y offset, rotation, scale)
 *   -NumberOfChannels <int>       Number of channels if OME metadata is unavailable (default: 1)
 *   -FilesSplitByChannel          Input frame order is channel-blocked instead of interleaved
 *   -Output <string>              Output base name override
 */

#include "BLFlagParser.h"
#include <stdexcept> 

int Align_Channels(std::string fileName, int startFrame, int endFrame, size_t positionIn, std::vector<std::vector<float>>& alignments, bool skipIndependentDrifts, float maxShift, bool outputAligned, int numOfChannels = 1, bool filesSplitByChannelIn = false, std::string outputBaseString = "");


int main(int argc, char *argv[])
{

	if (argc == 1 || (std::string(argv[1]).substr(0, 2) == "-h" || std::string(argv[1]).substr(0, 2) == "-H")) {
		std::cout << "Usage: Align_Channels <fileName> [options]\n";
		std::cout << "Options:\n";
		std::cout << "-Start i (Default i = 1) Specify frame i initially align from\n";
		std::cout << "-End i (Default i = total number of frames) Specify frame i to initially align to\n";
		std::cout << "-Position i (Default i = 0 (all)) Specify position to analyse, setting to 0 analyzes all positions \n";
		std::cout << "-MaxShift i (Default i = unlimited) The maximum amount of drift in x and y that will be searched for during alignment\n";
		std::cout << "-OutputAligned (Default false) Save the aligned image stacks\n";
		std::cout << "-SkipIndependentDrifts (Default false) Only Generate combined drifts, For Channel to Channel alignment use the reference frames\n";
		std::cout << "-Alignment Manually input the alignment between channels. Requires 4 values per extra channel (x offset ch2, ch2... yoffset ch2 ch3..., rotation ch2 ch3... scale ch2 ch3...)\n";
		std::cout << "-NumberOfChannels i (Default i = 1) Sets the number of channels to split the file into. Only used if no OME metadata is present. \n";
		std::cout << "-FilesSplitByChannel Images ordered by channel rather than alternating. Only used if no OME metadata is present. \n";
		std::cout << "-Output <name> Override the output base name for generated files.\n";
		return 0;
	}


	bool inputalignment = false,skipIndependentDrifts = false;
	int start = 1, end = -1, position = 0, numOfChan = 1;
	std::vector<std::vector<float>> alignments;
	std::vector<std::vector<float>> drifts;
	float maxShift = FLT_MAX;
	bool outputAligned = false, filesSplitByChannel = false;
	std::string outputfile="";

	std::string fileName = std::string(argv[1]);

	alignments = std::vector<std::vector<float>>();
	std::vector<float> alignmentArguments;

	std::vector<std::pair<std::string, int*>> intFlags = {{"Start", &start},{"End", &end},{"Position", &position},{"NumberOfChannels", &numOfChan} };
	std::vector<std::pair<std::string, float*>> floatFlags = {{"MaxShift", &maxShift} };
	std::vector<std::pair<std::string, bool*>> boolFlags = { {"OutputAligned", &outputAligned}, {"SkipIndependentDrifts", &skipIndependentDrifts},{"FilesSplitByChannel",&filesSplitByChannel} };
	std::vector<std::pair<std::string, std::vector<float>*>> vecFlags = { {"Alignment", &alignmentArguments} };
	std::vector<std::pair<std::string, std::string*>> stringFlags = {{"Output", &outputfile} };

	if (BLFlagParser::parseValues(intFlags, argc, argv)) return 1;
	if (BLFlagParser::parseValues(floatFlags, argc, argv)) return 1;
	if (BLFlagParser::parseValues(boolFlags, argc, argv)) return 1;
	if (BLFlagParser::parseValues(vecFlags, argc, argv)) return 1;
	if (BLFlagParser::parseValues(stringFlags, argc, argv)) return 1;


	if (alignmentArguments.size()>0 && alignmentArguments.size() % 4 != 0 )throw std::invalid_argument("Not Enough Alignment Inputs.\nRequires 4 values per extra channel (x offset ch2 ch2... yoffset ch2 ch3..., rotation ch2 ch3... scale ch2 ch3...)\n");
	if (alignmentArguments.size() >0) {
		alignments = std::vector<std::vector<float>>(alignmentArguments.size()/4, std::vector<float>(4, 0.0f));
		for (size_t i = 0; i < alignments.size(); i++)for (size_t j = 0; j < 4; j++)alignments[i][j] = alignmentArguments[j + i * 4];
	}

	return Align_Channels(fileName, start, end, position, alignments, skipIndependentDrifts, maxShift, outputAligned, numOfChan, filesSplitByChannel, outputfile);

	//system("PAUSE");

}
