#include<vector>
#include <iostream>
#include "findStepHeader.hpp"


void aggarwalStepFit(std::vector<double> tofit, double stepPenalty, int maxSteps, std::vector<int>& fitPoints, std::vector<double>& fitMeans) {
	
	double stddev = approxNoiseStdDev(std::vector<std::vector<double>>(1,tofit));
	stepPenalty = stepPenalty * stepPenalty * stddev * stddev;
	//std::cout << stddev << "\n";
	
	std::vector<std::vector<int>> savedpoints(maxSteps+1);
	std::vector<std::vector<double>> savedmeans(maxSteps + 1);

	std::vector <int> points, proposedpoints;
	std::vector<double> variance, proposedvar1, proposedvar2,means,proposedmeans1,proposedmeans2, totalJ;

	double var1 = 0, var2 = 0, mean1, mean2;
	int pos = 0, minJPos = 0;

	//initialise point list and variance
	double initialVariance = calculateL2(&tofit[0], (int)tofit.size(),mean1);
	means.push_back(mean1);
	savedmeans[0] = means;
	variance.push_back(initialVariance);

	//initialise J

	totalJ.push_back(initialVariance);
	double minJ = initialVariance;


	//initilise proposed points and variance
	findstepL2(tofit.data(), (int)tofit.size(), mean1, mean2, var1, var2, pos);
	proposedpoints.push_back(pos);
	proposedvar1.push_back(var1);
	proposedvar2.push_back(var2);
	proposedmeans1.push_back(mean1);
	proposedmeans2.push_back(mean2);



	//cout << "starting " << variance[0] << " " << proposedpoints[0] << " " << proposedvar1[0] << " " << proposedvar2[0] << " " << (var1 + var2) / sum1 << "\n";

	for (int stepCount = 0; stepCount < maxSteps; stepCount++) {
		//find proposed point with minimum variance
		double minPorposedVar = DBL_MAX;
		int minSection = 0;
		for (int i = 0; i < proposedpoints.size(); i++) {
			double varSum = proposedvar1[i] + proposedvar2[i];
			for (int j = 0; j < variance.size(); j++)if (j != i)varSum += variance[j];

			if (varSum < minPorposedVar) {
				minPorposedVar = varSum;
				minSection = i;
			}
		}
		//add point to list and variance
		points.insert(points.begin() + minSection, proposedpoints[minSection]);
		variance[minSection] = proposedvar2[minSection];
		variance.insert(variance.begin() + minSection, proposedvar1[minSection]);
		means[minSection] = proposedmeans2[minSection];
		means.insert(means.begin() + minSection, proposedmeans1[minSection]);


		//calculate new proposed point right side
		size_t newSize = minSection >= points.size() - 1 ? tofit.size() - points[minSection] : points[minSection + 1] - points[minSection];//If its the last step go to the end of data
		findstepL2(&tofit[points[minSection]], newSize, mean1, mean2, var1, var2, pos);
		pos += points[minSection];
		proposedpoints[minSection] = pos;
		proposedvar1[minSection] = var1;
		proposedvar2[minSection] = var2;
		proposedmeans1[minSection] = mean1;
		proposedmeans2[minSection] = mean2;


		//calculate new proposed point left side
		int prevPoint = minSection > 0 ? points[minSection - 1] : 0;
		newSize = points[minSection] - prevPoint;
		findstepL2(&tofit[prevPoint], newSize, mean1, mean2, var1, var2, pos);
		if (minSection > 0) pos += points[minSection - 1];
		proposedpoints.insert(proposedpoints.begin() + minSection, pos);
		proposedvar1.insert(proposedvar1.begin() + minSection, var1);
		proposedvar2.insert(proposedvar2.begin() + minSection, var2);
		proposedmeans1.insert(proposedmeans1.begin() + minSection, mean1);
		proposedmeans2.insert(proposedmeans2.begin() + minSection, mean2);


		//save variance and J

		savedpoints[stepCount+1] = points;
		savedmeans[stepCount + 1] = means;

		var1 = 0;
		for (int i = 0; i < variance.size(); i++)var1 += variance[i];
		totalJ.push_back(var1 + stepPenalty * (points.size()));

		//std::cout << var1 << " " << stepPenalty * (points.size()) << " " << var1 + stepPenalty * (points.size()) <<"\n";

		if (totalJ[stepCount + 1] < minJ) {
			minJ = totalJ[stepCount + 1];
			minJPos = stepCount+1;
		}

		if (stepCount+1 - minJPos > 4)break;

	}


	fitPoints = savedpoints[minJPos];
	fitPoints.insert(fitPoints.begin(), 0);
	fitMeans = savedmeans[minJPos];
}
