#include <vector>
#include <iostream>     // std::cout
#include <random>       // std::default_random_engine
#include <chrono>       // std::chrono::system_clock
#include "BLCSVIO.h"

#include "findStepHeader.hpp"

int Step_Fitting(std::string output, std::string inputfile,double TThreshold, int maxSteps, int method) {

	std::vector<std::vector<double>> alltofit(3000, std::vector<double>(1000, 0));
	std::vector<std::string> headerLine;
	BLCSVIO::readVariableWidthCSV(inputfile, alltofit, headerLine);

	if (maxSteps < 0)maxSteps = alltofit.size() / 2;

	std::vector<std::vector<int>> stepPoints(alltofit.size());
	std::vector<std::vector<double>> stepMeans(alltofit.size());

	//double stdDev = 0;
	//if(method==0)stdDev = approxNoiseStdDev(alltofit);

	//std::cout << stdDev << " " << TThreshold << " " << TThreshold * TThreshold * stdDev * stdDev << "\n";

	for (int fitCount = 0; fitCount < alltofit.size(); fitCount++) {
		if (method == 0)aggarwalStepFit(alltofit[fitCount], TThreshold, maxSteps, stepPoints[fitCount], stepMeans[fitCount]);
		if (method == 1)stasiStepFit(alltofit[fitCount], TThreshold, maxSteps, stepPoints[fitCount], stepMeans[fitCount]);
		if (method == 2)autoStepFinder(alltofit[fitCount], maxSteps, stepPoints[fitCount], stepMeans[fitCount]);
		if (method == 3) {
			int iterations = 1000;
			heuristicChangePointStepFit(alltofit[fitCount], TThreshold, iterations, maxSteps, stepPoints[fitCount], stepMeans[fitCount]);
		}
	}

	BLCSVIO::writeCSV(output + "_StepPoints.csv", stepPoints, "Each row is a particle. Each column first frame of a new step. First frame is 0\n");
	BLCSVIO::writeCSV(output + "_StepMeans.csv", stepMeans, "Each row is a particle. Each column first frame of a new step. First frame is 0\n");

	return 0;
}