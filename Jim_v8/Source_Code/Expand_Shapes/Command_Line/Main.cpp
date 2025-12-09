/*
 * Main.cpp - Expand_Shapes
 *
 * Description:
 *   This program generates expanded foreground and background pixel regions for each detected
 *   particle based on an input CSV of labeled pixel positions. These expanded regions can then
 *   be used to compute fluorescence traces for individual particles over time.
 *
 *
 * Input Arguments:
 *   argv[1]  - Path to CSV file with foreground pixel positions.
 *   argv[2]  - Path to CSV file with background pixel positions.
 *   argv[3]  - Output base name for image and CSV files.
 *
 * Optional Flags:
 *   --boundaryDist <float>        : Radius (in pixels) for foreground inclusion zone (default: 4.1)
 *   --backInnerRadius <float>    : Inner radius for background exclusion zone (default: = boundaryDist)
 *   --backgroundDist <float>     : Radius (in pixels) for background region (default: 20)
 *   --extraBackgroundFile <file> : Optional CSV file specifying additional background pixels
 *   --channelAlignment <file>    : CSV file containing alignment parameters for multi-channel output
 *
 * Output Files:
 *   - <output>_ROIs.tif                       : Binary image showing expanded foreground ROIs.
 *   - <output>_Background_Regions.tif         : Binary image of expanded background regions.
 *   - <output>_ROI_Positions_Channel_*.csv    : Foreground pixel positions per channel.
 *   - <output>_Background_Positions_Channel_*.csv : Background pixel positions per channel.
 *
 * Dependencies:
 *   - BLCSVIO: Custom CSV parser for variable-width image region data.
 *   - BLTiffIO: Custom TIFF image I/O for saving masks.
 *   - BLFlagParser: Lightweight CLI flag parsing utility.
 *
 * Notes:
 *   - Pixel coordinates are stored in raster-order linear index format: `x + y * width`.
 *   - The first line in each output CSV contains image dimensions and pixel count.
 *   - Pixels are only assigned to foreground/background if they pass all distance and exclusion checks.
 *   - The geometric transformation supports rigid and affine alignment using 2D matrices and translations.
 *
 * @author James Walsh james.walsh@phys.unsw.edu.au
 * @date 2025-07-14
 */


#include <string>
#include <iostream>
#include <vector>
#include "BLFlagParser.h"


int Expand_Shapes(std::string output, std::string foregroundposfile, std::string backgroundposfile, std::string extraBackgroundFileName, std::string channelAlignmentFileName, float boundaryDist, float backinnerradius, float backgroundDist);

int main(int argc, char *argv[])
{

	float boundaryDist = 4.1f, backgroundDist = 20.0f, backinnerradius = 0.0f;

	bool bExtraBackground = false, bChannelAlignment = false;
	std::string extraBackgroundFileName = "", channelAlignmentFileName = "";


	if (argc < 4) { std::cout << "could not read file name.\n"; return 1; }
	std::string foregroundposfile = argv[1];
	std::string backgroundposfile = argv[2];
	std::string output = argv[3];

	std::vector<std::pair<std::string, float*>> floatFlags = { {"boundaryDist", &boundaryDist},{"backInnerRadius", &backinnerradius},{"backgroundDist", &backgroundDist} };
	std::vector<std::pair<std::string, std::string*>> stringFlags = { {"extraBackgroundFile", &extraBackgroundFileName},{"channelAlignment", &channelAlignmentFileName}};

	if (BLFlagParser::parseValues(floatFlags, argc, argv)) return 1;
	if (BLFlagParser::parseValues(stringFlags, argc, argv)) return 1;

	if (extraBackgroundFileName.length() > 1)bExtraBackground = true;
	if (channelAlignmentFileName.length() > 1)bChannelAlignment = true;

	if (backinnerradius < boundaryDist)backinnerradius = boundaryDist;


	return Expand_Shapes(output, foregroundposfile, backgroundposfile, extraBackgroundFileName, channelAlignmentFileName, boundaryDist, backinnerradius, backgroundDist);

};
