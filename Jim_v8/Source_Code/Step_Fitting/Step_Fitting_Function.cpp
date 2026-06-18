#include <vector>
#include  <filesystem>
#include "BLCSVIO.h"
#include "findStepHeader.hpp"

int Step_Fitting(std::string inputfile,double TThreshold = 1.96, int method = 0 , int maxSteps = -1, std::string output="") {

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



	if (output == "") output = "StepFit";
	
	
	std::string filesepin(1, std::filesystem::path::preferred_separator);
	std::string filesep = filesepin;
	std::string fileBase = std::filesystem::path(inputfile).parent_path().generic_string() + filesep + "StepFit";


	BLCSVIO::writeCSV(fileBase + "_StepPoints.csv", stepPoints, "Each row is a particle. Each column first frame of a new step. First frame is 0\n");
	BLCSVIO::writeCSV(fileBase + "_StepMeans.csv", stepMeans, "Each row is a particle. Each column is the height of the next step\n");

	return 0;
}