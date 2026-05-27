/*
 * Calculate_Traces Main.cpp
 *
 * Description:
 *   This program extracts fluorescence intensity time traces from regions of interest (ROIs)
 *   in a multi-frame TIFF image stack. For each ROI, it computes total and background-subtracted
 *   fluorescence across all frames, with optional drift correction.
 *
 *   The program reads:
 *     - A TIFF image stack.
 *     - A CSV file listing ROI pixel indices.
 *     - A CSV file listing background pixel indices for each ROI.
 *     - (Optional) A CSV file with frame-by-frame XY drift values.
 *
 *   For each ROI and frame, it computes the background-subtracted total intensity.
 *
 *   The results are output to:
 *     - A fluorescence intensity CSV (background-subtracted).
 *     - A background intensity CSV.
 *     - A verbose trace CSV (if -Verbose flag is set), containing full statistical detail.
 *
 * Usage:
 *   Calculate_Traces <TIFF_Image> <ROI_CSV> <Background_CSV> <Output_Base> [-Drift <Drift_CSV>] [-Verbose]
 *
 * Dependencies:
 *   - BLTiffIO: For reading TIFF image stacks.
 *   - BLCSVIO: For reading/writing CSV files.
 *   - BLImageTransform: For drift correction handling (if used).
 *
 * Author: James Walsh
 * Date: July 2020
 */

#include <string>
#include <iostream>
#include <vector>

int Calculate_Traces(std::string fileName, size_t positionIn, size_t channelIn, std::string ROIfile, std::string backgroundfile, int startFrame = 1, int endFrame = -1, std::string driftfile = "", std::string weightImageFile = "", int numOfChannels = 1, bool filesSplitByChannelIn = false);

int main(int argc, char *argv[])
{
	if (argc < 6) { std::cout << "could not read file name" << "\n"; return 1; }
	std::string inputfile = argv[1];
	size_t positionIn = std::stoi(argv[2]);
	size_t channelIn = std::stoi(argv[3]);
	std::string ROIfile = argv[4];
	std::string backgroundfile = argv[5];

	bool veboseoutput = false;
	std::string driftfile = "", weightsfile = "";
	int startFrame = 1, endFrame = -1;

	for (int i = 1; i < argc; i++) {
		if (std::string(argv[i]) == "-Drift") {
			if (i + 1 < argc) {
				driftfile = argv[i + 1];
				std::cout << "Drifts imported from " << driftfile << "\n";
			}
			else { std::cout << "error inputting drifts\n" ; return 1; }
		}
		if (std::string(argv[i]) == "-startFrame") {
			if (i + 1 < argc) {
				startFrame = std::stoi(argv[i + 1]);
				std::cout << "Traces starting from frame " << startFrame << "\n";
			}
			else { std::cout << "error inputting start Frame \n" ; return 1; }
		}
		if (std::string(argv[i]) == "-endFrame") {
			if (i + 1 < argc) {
				endFrame = std::stoi(argv[i + 1]);
				std::cout << "Traces ending at frame " << endFrame << "\n";
			}
			else { std::cout << "error inputting end Frame \n"; return 1; }
		}
		if (std::string(argv[i]) == "-Weights") {
			if (i + 1 < argc) {
				weightsfile = argv[i + 1];
				std::cout << "Weights imported from " << weightsfile << "\n";
			}
			else { std::cout << "error inputting Weights\n"; return 1; }
		}
	}


	return Calculate_Traces(inputfile, positionIn, channelIn, ROIfile, backgroundfile, startFrame,endFrame, driftfile, weightsfile);
}