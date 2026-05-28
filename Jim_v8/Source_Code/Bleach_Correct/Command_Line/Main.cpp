/******************************************************************************
 * Bleach_Correct - Main.cpp
 *
 * Description:
 *   This program performs photobleaching correction on time-resolved fluorescence
 *   intensity traces. It assumes that the observed signal is a convolution of
 *   a non-negative binding signal and an exponential decay due to photobleaching.
 *
 *   The user provides a mean bleaching frame number (meanBleachFrame), which defines
 *   the decay timescale. For each input trace, the program solves the linear system:
 *
 *       A * x ≈ b  subject to x ≥ 0,
 *
 *   where A is a matrix encoding the exponential decay kernel, b is the observed
 *   intensity trace, and x is the recovered (non-negative) binding signal.
 *
 *   The solution is computed using non-negative least squares (NNLS).
 *   The recovered signal is integrated to obtain the bleach-corrected trace.
 *
 * Input:
 *   - A CSV file of fluorescence intensity traces (one trace per row).
 *   - The output file prefix.
 *   - The mean bleach frame number (a positive float).
 *
 * Output:
 *   - [prefix]_Bleach_Fit.csv        : Reconstructed decay-convolved fits (A * x).
 *   - [prefix]_Bleach_Corrected.csv : Estimated bleach-corrected binding traces
 *                                     (cumulative sum of x).
 *
 * Dependencies:
 *   - BLCSVIO.h: A custom header providing CSV read/write utilities.
 *   - NNLS.cpp:   A function implementing non-negative least squares fitting.
 *
 * Author:
 *   James Walsh  james.walsh@phys.unsw.edu.au
 *   Date: 2025-07-16
 ******************************************************************************/

#include <vector>
#include <iostream>     // std::cout
#include <string> 
#include <numeric>
#include "BLCSVIO.h"

int Bleach_Correct(std::string fileBase, std::string inputfile, double meanBleachFrame);


int main(int argc, char* argv[])
{
    if (argc == 1 || (std::string(argv[1]).substr(0, 2) == "-h" || std::string(argv[1]).substr(0, 2) == "-H")) {
        std::cout << "Usage: Bleach_Correct <input_csv> <output_base> <mean_bleach_frame>\n";
        std::cout << "  input_csv         CSV file containing traces (one trace per row)\n";
        std::cout << "  output_base       Base name used for generated output CSV files\n";
        std::cout << "  mean_bleach_frame Positive decay timescale parameter for bleaching correction\n";
        return 0;
    }

    if (argc < 4) {
        std::cout << "Insufficient arguments.\n";
        std::cout << "Usage: Bleach_Correct <input_csv> <output_base> <mean_bleach_frame>\n";
        return 1;
    }
    std::string inputfile = argv[1];
    std::string output = argv[2];
    double meanBleachFrame = std::stod(argv[3]);

    Bleach_Correct(output, inputfile, meanBleachFrame);

    return 0;
}            
