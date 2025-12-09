/*
 * Detect_Particles main.cpp
 *
 * Description:
 *   This program performs particle detection on an image using Laplacian of Gaussian (LoG) filtering,
 *   followed by binarization, and optional filtering based on shape, size, and position criteria.
 *
 * Usage:
 *   Detect_Particles <TIFF_Image> <Output_Base> [Optional Parameters]
 *
 * Optional Parameters:
 *   -BinarizeCutoff <float>           : Threshold multiplier for binarization (default 0.2)
 *   -minDistFromEdge <float>         : Minimum distance from all edges (overrides specific edges if larger)
 *   -left/-right/-top/-bottom <float>: Minimum distance from respective image edge
 *   -minEccentricity/-maxEccentricity<float>: Eccentricity filter
 *   -minLength/-maxLength <float>    : Length of major axis filter
 *   -minCount/-maxCount <float>      : Minimum/maximum number of pixels per region
 *   -maxDistFromLinear <float>       : Deviation from best-fit line
 *   -minSeparation <float>           : Minimum separation between region centers
 *   -GaussianStdDev <float>          : Standard deviation for LoG filter (default 5)
 *   -includeSmall                    : Include small regions in nearest neighbour calculations and for background ROI output
 *
 * Outputs (written to <Output_Base>.*):
 *   - _Regions.tif                   : Binary image showing detected ROIs
 *   - _Measurements.csv              : Raw measurements of all ROIs
 *   - _Positions.csv                 : Raw pixel positions of all ROIs
 *   - _Filtered_Regions.tif          : Binary image of filtered ROIs
 *   - _Filtered_Region_Numbers.tif   : ROI labels overlaid as indexed pixels
 *   - _Filtered_Measurements.csv     : Measurements of ROIs after filtering
 *   - _Filtered_Positions.csv        : Positions of ROIs after filtering
 *
 * Dependencies:
 *   - BLTiffIO: For TIFF input/output
 *   - BLCSVIO: For CSV input/output
 *   - BLImageTransform: For image filtering and analysis
 *   - BLFlagParser: For parsing command-line arguments
 *
 * @author James Walsh james.walsh@phys.unsw.edu.au
 * @date 2025-07-14
 */


#include <iostream>
#include <vector>
#include <algorithm>
#include "BLTiffIO.h"
#include "BLCSVIO.h"
#include "BLImageTransform.h"
#include "BLFlagParser.h"


int Detect_Particles(std::string fileBase, std::string inputfile, double gaussStdDev, double binarizecutoff, double minSeparation, double leftminDistFromEdge, double rightminDistFromEdge, double topminDistFromEdge, double bottomminDistFromEdge,
	double minEccentricity, double maxEccentricity, double minLength, double maxLength, double minCount, double maxCount, double maxDistFromLinear, bool includeSmall);


int main(int argc, char *argv[])
{

	float binarizecutoff = 0.2f;
	float minEccentricity = -0.1f, maxEccentricity = 1.1f, minLength = 0.0f, maxLength = 10000000000.0f, minCount = 0.0f, maxCount = 1000000000.0f, maxDistFromLinear = 10000000.0f;
	bool filtering = false;

	float leftminDistFromEdge = -0.1f, rightminDistFromEdge = -0.1f, topminDistFromEdge = -0.1f, bottomminDistFromEdge = -0.1f,allminDistFromEdge = -0.1f;

	float minSeparation = -1000.0f;

	float gaussStdDev = -1.0f;
	bool logStdDevChanged = false;
	bool includeSmall = false;

	//read in parameters

	if (argc < 3) { std::cout << "could not read file name\n"; return 1; }
	std::string inputfile = argv[1];
	std::string output = argv[2];

	std::vector<std::pair<std::string, float*> >params{ std::make_pair("BinarizeCutoff", &binarizecutoff),std::make_pair("minDistFromEdge", &allminDistFromEdge),
		std::make_pair("left", &leftminDistFromEdge),std::make_pair("right", &rightminDistFromEdge),std::make_pair("top", &topminDistFromEdge),std::make_pair("bottom", &bottomminDistFromEdge),
		std::make_pair("minEccentricity", &minEccentricity),std::make_pair("maxEccentricity", &maxEccentricity),std::make_pair("minLength", &minLength),std::make_pair("maxLength", &maxLength),
		std::make_pair("minCount", &minCount),std::make_pair("maxCount", &maxCount),std::make_pair("maxDistFromLinear", &maxDistFromLinear),std::make_pair("minSeparation", &minSeparation),
		std::make_pair("GaussianStdDev", &gaussStdDev) };

	if (BLFlagParser::parseValues(params, argc, argv)) return 1;

	if (allminDistFromEdge > leftminDistFromEdge)leftminDistFromEdge = allminDistFromEdge;
	if (allminDistFromEdge > rightminDistFromEdge)rightminDistFromEdge = allminDistFromEdge;
	if (allminDistFromEdge > topminDistFromEdge)topminDistFromEdge = allminDistFromEdge;
	if (allminDistFromEdge > bottomminDistFromEdge)bottomminDistFromEdge = allminDistFromEdge;

	if (gaussStdDev > 0) logStdDevChanged = true;
	else gaussStdDev = 5;

	std::vector<std::pair<std::string, bool*> > boolparams{ std::make_pair("includeSmall", &includeSmall) };
	if (BLFlagParser::parseValues(boolparams, argc, argv)) return 1;


	

	return Detect_Particles(output, inputfile, gaussStdDev, binarizecutoff, minSeparation, leftminDistFromEdge, rightminDistFromEdge, topminDistFromEdge, bottomminDistFromEdge,
		minEccentricity, maxEccentricity, minLength, maxLength, minCount, maxCount, maxDistFromLinear, includeSmall);
}