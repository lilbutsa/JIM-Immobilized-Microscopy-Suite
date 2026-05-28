/*
 * Detect_Particles main.cpp
 *
 * Description:
 *   This program performs particle detection on an image using Laplacian of Gaussian (LoG) filtering,
 *   followed by binarization, and optional filtering based on shape, size, and position criteria.
 *
 * Usage:
 *   Detect_Particles <TIFF_Image> <BinarizeCutoff> [Optional Parameters]
 *
 * Optional Parameters:
 *   -Output <string>                 : Output base name override
 *   -MinDistFromEdge <float>         : Minimum distance from all edges (overrides specific edges if larger)
 *   -LeftMinDistFromEdge <float>     : Minimum distance from left edge
 *   -RightMinDistFromEdge <float>    : Minimum distance from right edge
 *   -TopMinDistFromEdge <float>      : Minimum distance from top edge
 *   -BottomMinDistFromEdge <float>   : Minimum distance from bottom edge
 *   -MinEccentricity/-MaxEccentricity <float> : Eccentricity filter bounds
 *   -MinLength/-MaxLength <float>    : Major-axis length filter bounds
 *   -MinCount/-MaxCount <float>      : Pixel-count filter bounds
 *   -MaxDistFromLinear <float>       : Deviation from best-fit line
 *   -MinSeparation <float>           : Minimum separation between region centers
 *   -GaussianStdDev <float>          : Standard deviation for LoG filter (default 5)
 *   -IncludeSmall                    : Include small regions in nearest-neighbour and background ROI calculations
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
#include "BLFlagParser.h"


int Detect_Particles(std::string fileBase, std::string inputfile, double gaussStdDev, double binarizecutoff, double minSeparation, double leftminDistFromEdge, double rightminDistFromEdge, double topminDistFromEdge, double bottomminDistFromEdge,
	double minEccentricity, double maxEccentricity, double minLength, double maxLength, double minCount, double maxCount, double maxDistFromLinear, bool includeSmall);


int main(int argc, char *argv[])
{
	if (argc == 1 || (std::string(argv[1]).substr(0, 2) == "-h" || std::string(argv[1]).substr(0, 2) == "-H")) {
		std::cout << "Usage: Detect_Particles <input_tiff> <binarize_cutoff> [options]\n";
		std::cout << "Options:\n";
		std::cout << "-Output <name> Output base name override.\n";
		std::cout << "-GaussianStdDev f (Default f = 5) Gaussian filter standard deviation.\n";
		std::cout << "-MinSeparation f (Default f = 0) Minimum center-to-center separation.\n";
		std::cout << "-MinDistFromEdge f Apply a common minimum distance from all image edges.\n";
		std::cout << "-LeftMinDistFromEdge f, -RightMinDistFromEdge f, -TopMinDistFromEdge f, -BottomMinDistFromEdge f\n";
		std::cout << "-MinEccentricity f, -MaxEccentricity f ROI eccentricity filter bounds.\n";
		std::cout << "-MinLength f, -MaxLength f Major-axis length filter bounds.\n";
		std::cout << "-MinCount f, -MaxCount f Pixel-count filter bounds.\n";
		std::cout << "-MaxDistFromLinear f Maximum deviation from local linear trend.\n";
		std::cout << "-IncludeSmall Include small regions in neighbour/background calculations.\n";
		return 0;
	}


	float minEccentricity = -0.1f, maxEccentricity = 1.1f, minLength = 0.0f, maxLength = 10000000000.0f, minCount = 0.0f, maxCount = 1000000000.0f, maxDistFromLinear = 10000000.0f;
	bool filtering = false;

	float leftminDistFromEdge = -0.1f, rightminDistFromEdge = -0.1f, topminDistFromEdge = -0.1f, bottomminDistFromEdge = -0.1f,allminDistFromEdge = -0.1f;

	float minSeparation = 0;

	float gaussStdDev = -1.0f;
	bool logStdDevChanged = false;
	bool includeSmall = false;

	//read in parameters

	if (argc < 3) {
		std::cout << "Insufficient arguments.\n";
		std::cout << "Usage: Detect_Particles <input_tiff> <binarize_cutoff> [options]\n";
		return 1;
	}
	std::string inputfile = argv[1];
	float binarizecutoff = std::stod(argv[2]);

	std::string output = "";

	std::vector<std::pair<std::string, std::string*> >stringParams{ std::make_pair("Output", &output) };
	if (BLFlagParser::parseValues(stringParams, argc, argv)) return 1;


	std::vector<std::pair<std::string, float*> >params{ std::make_pair("MinDistFromEdge", &allminDistFromEdge),
		std::make_pair("LeftMinDistFromEdge", &leftminDistFromEdge),std::make_pair("RightMinDistFromEdge", &rightminDistFromEdge),std::make_pair("TopMinDistFromEdge", &topminDistFromEdge),std::make_pair("BottomMinDistFromEdge", &bottomminDistFromEdge),
		std::make_pair("MinEccentricity", &minEccentricity),std::make_pair("MaxEccentricity", &maxEccentricity),std::make_pair("MinLength", &minLength),std::make_pair("MaxLength", &maxLength),
		std::make_pair("MinCount", &minCount),std::make_pair("MaxCount", &maxCount),std::make_pair("MaxDistFromLinear", &maxDistFromLinear),std::make_pair("MinSeparation", &minSeparation),
		std::make_pair("GaussianStdDev", &gaussStdDev) };

	if (BLFlagParser::parseValues(params, argc, argv)) return 1;

	if (allminDistFromEdge > leftminDistFromEdge)leftminDistFromEdge = allminDistFromEdge;
	if (allminDistFromEdge > rightminDistFromEdge)rightminDistFromEdge = allminDistFromEdge;
	if (allminDistFromEdge > topminDistFromEdge)topminDistFromEdge = allminDistFromEdge;
	if (allminDistFromEdge > bottomminDistFromEdge)bottomminDistFromEdge = allminDistFromEdge;

	if (gaussStdDev > 0) logStdDevChanged = true;
	else gaussStdDev = 5;

	std::vector<std::pair<std::string, bool*> > boolparams{ std::make_pair("IncludeSmall", &includeSmall) };
	if (BLFlagParser::parseValues(boolparams, argc, argv)) return 1;


	

	return Detect_Particles(output, inputfile, gaussStdDev, binarizecutoff, minSeparation, leftminDistFromEdge, rightminDistFromEdge, topminDistFromEdge, bottomminDistFromEdge,
		minEccentricity, maxEccentricity, minLength, maxLength, minCount, maxCount, maxDistFromLinear, includeSmall);
}
