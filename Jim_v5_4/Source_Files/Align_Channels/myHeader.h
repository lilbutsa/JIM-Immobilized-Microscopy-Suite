#pragma once
#include <string>
#include <iostream>
#include <vector>
#include <algorithm>
#include "ipp.h"
#include "BLTiffIO.h"
#include "BLImageTransform.h"
#include "BLCSVIO.h"


using namespace std;

void driftCorrectSingleChannel(string& inputfilename, int& start, int& end, int iterations, vector<float>& initialmeanimage, vector<float>& finalmeanimage, vector<vector<float>> &driftsout, int& imageWidth);
void alignMultiChannel(vector<string>& inputfilenames, int& start, int& end, int iterations, string outputfile, vector<vector<float>> &driftsout, int& imageWidth);

void driftCorrectMultiChannel(vector<string>& inputfilename, int& start, int& end, int iterations, vector<float>&angle, vector<float>&scale, vector<float>&xoffset, vector<float>&yoffset, vector<vector<float>>& initialmeanimage, vector<vector<float>>& finalmeanimage, vector<vector<float>> &driftsout, int& imageWidth);

void writeChannelAlignment(string outputfile, vector<float>&angle, vector<float>&scale, vector<float>&xoffset, vector<float>&yoffset, int imageWidth, int imageHeight);
