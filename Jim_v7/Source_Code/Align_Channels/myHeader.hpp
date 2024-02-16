
#include <string>
#include <iostream>
#include <vector>
#include <algorithm>
#include "ipp.h"
#include "BLTiffIO.h"
#include "BLImageTransform.h"
#include "BLCSVIO.h"
#include <cmath>


using namespace std;
void driftCorrect(vector<BLTiffIO::TiffInput*> is, vector< vector<float>> alignment, uint32_t start, uint32_t end, uint32_t iterations, uint32_t maxShift, string fileBase, bool bOutputStack, vector<float>& outputImage, std::string driftFileName);
void alignMultiChannel(vector<BLTiffIO::TiffInput*> is,uint32_t start, uint32_t end, uint32_t iterations, uint32_t maxShift, string fileBase, bool bOutputStack, vector<float>& maxIntensities, double SNRCutoff, bool bIndependentDrifts);
void writeChannelAlignment(string outputfile, vector< vector< float>>& alignments, int imageWidth, int imageHeight);
