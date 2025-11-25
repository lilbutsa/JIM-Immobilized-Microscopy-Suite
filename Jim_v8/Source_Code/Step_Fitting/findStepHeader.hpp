#pragma once
#include <vector>
void findstepL2(double* datain, int vecsize, double& mean1, double& mean2, double& L2_1, double& L2_2, int& pos);
void findstepTTest(double* datain, int vecsize, double& mean1, double& mean2, int& pos, double& maxTVal);
double calculateL2(double* datain, int vecsize, double& mean);
double approxNoiseStdDev(std::vector<std::vector<double>> dataIn);


void heuristicChangePointStepFit(std::vector<double> tofit, double TThreshold, int iterations, int maxSteps, std::vector<int>& fitPoints, std::vector<double>& fitMeans);
void autoStepFinder(std::vector<double> tofit, int maxSteps, std::vector<int>& fitPoints, std::vector<double>& fitMeans);
void stasiStepFit(std::vector<double> tofit, double minStepProb, int maxSteps, std::vector<int>& fitPoints, std::vector<double>& fitMeans);
void aggarwalStepFit(std::vector<double> tofit, double stepPenalty, int maxSteps, std::vector<int>& fitPoints, std::vector<double>& fitMeans);
