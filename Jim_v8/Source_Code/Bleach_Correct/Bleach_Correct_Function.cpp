#include <vector>
#include <iostream>     // std::cout
#include <string> 
#include <numeric>
#include "BLCSVIO.h"

int nnls(std::vector<std::vector<double>>& a, size_t m, size_t n, double* b, double* x, double* rnorm, double* wp, double* zzp, int* indexp);

int Bleach_Correct(std::string fileBase, std::string inputfile, double meanBleachFrame) {


    std::cout << "Bleach Correcting File " << inputfile << "\n";

    std::vector<std::vector<double>> traces;
    std::vector < std::string> headerLine;

    traces.reserve(3000);

    BLCSVIO::readVariableWidthCSV(inputfile, traces, headerLine);

    size_t m = traces[0].size();

    std::cout << traces.size() << " Traces " << m << " Frames\n";


    std::vector<double> fitOut(m, 0.0);
    std::vector<std::vector<double>> bleachCorrected(traces.size(), std::vector<double>(m, 0));
    std::vector<std::vector<double>> bleachFit(traces.size(), std::vector<double>(m, 0));

    std::vector < std::vector<double>> aMat(m, std::vector<double>(m, 0.0));
    std::vector < std::vector<double>> aMatHold(m, std::vector<double>(m, 0.0));
    for (size_t i = 0;i < m;i++) for (size_t j = i;j < m;j++)aMatHold[i][j] = exp((double)-1.0 * (j - i) / meanBleachFrame);

    double rnorm;
    std::vector<double> wp(m), zzp(m);
    std::vector<int> indexp(m);

    for (int traceCount = 0;traceCount < traces.size();traceCount++) {
        aMat = aMatHold;
        int retVal = nnls(aMat, m, m, traces[traceCount].data(), fitOut.data(), &rnorm, wp.data(), zzp.data(), indexp.data());
        //int retVal = nnls(aMat, traces[traceCount], fitOut, &rnorm);

        for (int i = 0;i < m;i++)for (int j = 0;j < m;j++)bleachFit[traceCount][i] += aMatHold[j][i] * fitOut[j];
        std::partial_sum(fitOut.begin(), fitOut.end(), bleachCorrected[traceCount].begin());
    }

    headerLine.push_back("Bleach Corrected With Mean Bleach Frame =");
    headerLine.push_back(std::to_string(meanBleachFrame));

    BLCSVIO::writeCSV(fileBase + "_Bleach_Fit.csv", bleachFit, headerLine);
    BLCSVIO::writeCSV(fileBase + "_Bleach_Corrected.csv", bleachCorrected, headerLine);

    return 0;

}