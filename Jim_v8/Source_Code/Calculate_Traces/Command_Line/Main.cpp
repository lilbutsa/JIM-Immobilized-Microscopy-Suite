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

int Calculate_Traces(std::string output, std::string inputfile, std::string ROIfile, std::string backgroundfile, std::string driftfile, bool veboseoutput);

int main(int argc, char *argv[])
{
	if (argc < 5) { std::cout << "could not read file name" << "\n"; return 1; }
	std::string inputfile = argv[1];
	std::string ROIfile = argv[2];
	std::string backgroundfile = argv[3];
	std::string output = argv[4];

	bool veboseoutput = false;
	std::string driftfile = "";

	for (int i = 1; i < argc; i++) {
		if (std::string(argv[i]) == "-Drift") {
			if (i + 1 < argc) {
				driftfile = argv[i + 1];
				std::cout << "Drifts imported from " << driftfile << "\n";
			}
			else { std::cout << "error inputting drifts" << std::endl; return 1; }
		}
		if (std::string(argv[i]) == "-Verbose")veboseoutput = true;
	}

	return Calculate_Traces(output, inputfile, ROIfile, backgroundfile, driftfile, veboseoutput);
}