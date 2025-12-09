
#include <vector>
#include <iostream>     // std::cout
#include <random>       // std::default_random_engine
#include <chrono>       // std::chrono::system_clock
#include <numeric>
#include <functional>
#include "findStepHeader.hpp"

double cusum(std::vector<double> datain) {
	std::partial_sum(datain.begin(), datain.end(), datain.begin());
	double min = *std::min_element(datain.begin(), datain.end());
	double max = *std::max_element(datain.begin(), datain.end());
	return (max-min);

}

double stepprob(double* datain,int vecsize, int numofbootstraps) {
	if (vecsize < 2) {
		return 0;
	}
	
	
	double sdiff0, mean;
	int lowerrand;

	std::vector<double> dataMeanSubtracted(vecsize);
	mean = std::accumulate(datain, datain+vecsize, 0.0f);
	mean = mean / vecsize;

	std::transform(datain, datain+vecsize, datain, [mean](auto x) { return x - mean; });

	sdiff0 = cusum(dataMeanSubtracted);

	lowerrand = 0;

	// obtain a time-based seed:
	unsigned seed = std::chrono::system_clock::now().time_since_epoch().count();

	for (int i = 0; i < numofbootstraps; i++) {
		//myshuffle(datain.data(), datain.size());
		shuffle(dataMeanSubtracted.begin(), dataMeanSubtracted.end(), std::default_random_engine(seed));
		if (cusum(dataMeanSubtracted) < sdiff0)lowerrand++;
	}
	return (double)lowerrand / (double)numofbootstraps;

}


void heuristicChangePointStepFit(std::vector<double> tofit, double TThreshold,int iterations, int maxSteps, std::vector<int>& fitPoints, std::vector<double>& fitMeans) {
	double minStepProb = erf(TThreshold);
	std::vector<std::vector<int>> savedpoints(maxSteps + 1);
	std::vector<std::vector<double>> savedmeans(maxSteps + 1);

	std::vector <int> points, proposedpoints;
	std::vector<double> means, proposedProbabilities, proposedmeans1, proposedmeans2;

	double TVal, mean1, mean2,var1,var2;
	int pos = 0;

	//initialise point list and variance

	mean1 = std::accumulate(tofit.begin(), tofit.end(), 0.0);
	mean1 = mean1 / tofit.size();

	means.push_back(mean1);
	savedmeans[0] = std::vector<double>(mean1, 1);


	//initilise proposed points and variance
	findstepL2(tofit.data(), tofit.size(), mean1, mean2,var1,var2, pos);
	TVal = stepprob(tofit.data(), tofit.size(), iterations);
	proposedpoints.push_back(pos);
	proposedProbabilities.push_back(TVal);
	proposedmeans1.push_back(mean1);
	proposedmeans2.push_back(mean2);

	//cout << "starting " << variance[0] << " " << proposedpoints[0] << " " << proposedvar1[0] << " " << proposedvar2[0] << " " << (var1 + var2) / sum1 << "\n";

	for (int stepCount = 0; stepCount < maxSteps; stepCount++) {
		//find proposed point with max TVal

		int minSection = std::distance(proposedProbabilities.begin(), std::max_element(proposedProbabilities.begin(), proposedProbabilities.end()));
		TVal = proposedProbabilities[minSection];

		if (TVal < minStepProb)break;


		//add point to list and variance
		points.insert(points.begin() + minSection, proposedpoints[minSection]);
		means[minSection] = proposedmeans2[minSection];
		means.insert(means.begin() + minSection, proposedmeans1[minSection]);


		//calculate new proposed point right side
		int newSize = minSection >= points.size() - 1 ? tofit.size() - points[minSection] : points[minSection + 1] - points[minSection];//If its the last step go to the end of data
		findstepL2(&tofit[points[minSection]], newSize, mean1, mean2,var1,var2, pos);
		TVal = stepprob(&tofit[points[minSection]], newSize, iterations);
		pos += points[minSection];
		proposedpoints[minSection] = pos;
		proposedProbabilities[minSection] = TVal;
		proposedmeans1[minSection] = mean1;
		proposedmeans2[minSection] = mean2;


		//calculate new proposed point left side
		int prevPoint = minSection > 0 ? points[minSection - 1] : 0;
		newSize = points[minSection] - prevPoint;
		findstepL2(&tofit[prevPoint], newSize, mean1, mean2,var1,var2, pos);
		TVal = stepprob(&tofit[prevPoint], newSize, iterations);
		if (minSection > 0) pos += points[minSection - 1];
		proposedpoints.insert(proposedpoints.begin() + minSection, pos);
		proposedProbabilities.insert(proposedProbabilities.begin() + minSection, TVal);
		proposedmeans1.insert(proposedmeans1.begin() + minSection, mean1);
		proposedmeans2.insert(proposedmeans2.begin() + minSection, mean2);


	}


	fitPoints = points;
	fitPoints.insert(fitPoints.begin(), 0);
	fitMeans = means;
}


