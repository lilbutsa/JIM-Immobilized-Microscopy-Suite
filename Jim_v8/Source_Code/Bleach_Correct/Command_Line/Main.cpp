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

    if (argc < 3) { std::cout << "could not read file name.\n"; return 1; }
    std::string inputfile = argv[1];
    std::string output = argv[2];
    double meanBleachFrame = std::stod(argv[3]);

    Bleach_Correct(output, inputfile, meanBleachFrame);

    return 0;
}            