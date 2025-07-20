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

int nnls(std::vector<std::vector<double>>& a,int m,int n,double* b,double* x,double* rnorm,double* wp,double* zzp,int* indexp);

using namespace std;

int main(int argc, char* argv[])
{

    if (argc < 3) { std::cout << "could not read file name" << endl; return 1; }
    std::string inputfile = argv[1];
    std::string output = argv[2];
    double meanBleachFrame = std::stod(argv[3]);

    cout << "Bleach Correcting File " << inputfile << "\n";

    vector<vector<double>> traces;
    vector < string> headerLine;

    traces.reserve(3000);

    BLCSVIO::readVariableWidthCSV(inputfile, traces, headerLine);

    int m = traces[0].size();

    cout << traces.size() <<" Traces " << m << " Frames\n";


    vector<double> fitOut(m, 0.0);
    vector<vector<double>> bleachCorrected(traces.size(), vector<double>(m, 0));
    vector<vector<double>> bleachFit(traces.size(), vector<double>(m, 0));

    std::vector < std::vector<double>> aMat(m, std::vector<double>(m,0.0));
    std::vector < std::vector<double>> aMatHold(m, std::vector<double>(m, 0.0));
    for (int i = 0;i < m;i++) for (int j = i;j < m;j++)aMatHold[i][j] = exp((double)-1.0*(j - i) / meanBleachFrame);

    double rnorm; 
    vector<double> wp(m), zzp(m);
    vector<int> indexp(m);

    for (int traceCount = 0;traceCount < traces.size();traceCount++) {
        aMat = aMatHold;
        int retVal = nnls(aMat, m, m, traces[traceCount].data(), fitOut.data(), &rnorm, wp.data(), zzp.data(), indexp.data());
        //int retVal = nnls(aMat, traces[traceCount], fitOut, &rnorm);

        for (int i = 0;i < m;i++)for (int j = 0;j < m;j++)bleachFit[traceCount][i] += aMatHold[j][i] * fitOut[j];
        std::partial_sum(fitOut.begin(), fitOut.end(), bleachCorrected[traceCount].begin());
    }

    headerLine.push_back("Bleach Corrected With Mean Bleach Frame =");
    headerLine.push_back(std::to_string(meanBleachFrame));

    BLCSVIO::writeCSV(output+"_Bleach_Fit.csv", bleachFit, headerLine);
    BLCSVIO::writeCSV(output + "_Bleach_Corrected.csv", bleachCorrected, headerLine);

}            