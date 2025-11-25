/*
 * Main.cpp - Picasso_Raw_Converter
 *
 * Description:
 *   This utility converts a multi-frame TIFF image stack into a binary .raw file
 *   and generates an accompanying .yaml metadata file compatible with
 *   the Picasso single-molecule localization microscopy (SMLM) analysis software suite.
 *
 *
 * Input Arguments:
 *   argv[1] - Input TIFF file.
 *   argv[2] - Output file base name (no extension; generates both .raw and .yaml).
 *
 * Output:
 *   - <outputName>.raw  : Binary stream of pixel values from all frames, stored sequentially.
 *                         Format: little-endian, 16-bit unsigned integers.
 *   - <outputName>.yaml : Metadata file describing image dimensions and data format,
 *                         as expected by Picasso for raw image import.
 *
 * Dependencies:
 *   - BLTiffIO: TIFF file I/O support.
 *
 * Usage Example:
 *   ./Picasso_Raw_Converter input_stack.tiff output_path/output_file
 *     → Generates output_file.raw and output_file.yaml
 *
 * Notes:
 *   - All image frames are read sequentially and stored contiguously.
 *   - Assumes input TIFF is properly formatted and readable via `BLTiffIO`.
 *
 * @author James Walsh james.walsh@phys.unsw.edu.au
 * @date 2025-07-14
 */

#include <string>
#include <iostream>
#include <vector>
#include "BLTiffIO.h"

int Picasso_Raw_Converter(std::string outputName, std::string fileIn);

int main(int argc, char* argv[])
{

	std::string fileIn, outputName;

	try {
		if (argc < 3)throw std::invalid_argument("Insufficient Arguments");
		fileIn = std::string(argv[1]);
		outputName = std::string(argv[2]);
	}
	catch (const std::invalid_argument & e) {
		std::cout << "Error Inputting Parameters\n";
		std::cout << e.what() << "\n";
		std::cout << "See -Help for help\n";
		return 1;
	}

	return Picasso_Raw_Converter(outputName, fileIn);
	
}