#include "findStepHeader.hpp"
#include <vector>
#include <numeric>


void stasiStepFit(std::vector<double> tofit, double minTVal, int maxSteps, std::vector<int>& fitPoints, std::vector<double>& fitMeans) {
	std::vector<std::vector<int>> savedpoints(maxSteps + 1);
	std::vector<std::vector<double>> savedmeans(maxSteps + 1);

	std::vector <int> points, proposedpoints;
	std::vector<double> means, proposedProbabilities, proposedmeans1, proposedmeans2;

	double TVal, mean1, mean2;
	int pos = 0;

	double sum1, sum2;
	//initialise point list and variance

	mean1 = std::accumulate(std::begin(tofit), std::end(tofit), 0.0f);
	mean1 = mean1 / tofit.size();

	means.push_back(mean1);
	savedmeans[0] = std::vector<double>(mean1, 1);


	//initilise proposed points and variance
	findstepTTest(tofit.data(), tofit.size(), mean1, mean2, pos, TVal);
	proposedpoints.push_back(pos);
	proposedProbabilities.push_back(TVal);
	proposedmeans1.push_back(mean1);
	proposedmeans2.push_back(mean2);

	//cout << "starting " << variance[0] << " " << proposedpoints[0] << " " << proposedvar1[0] << " " << proposedvar2[0] << " " << (var1 + var2) / sum1 << "\n";

	for (int stepCount = 0; stepCount < maxSteps; stepCount++) {
		//find proposed point with max TVal
		int minSection = std::distance(proposedProbabilities.begin(), std::max_element(proposedProbabilities.begin(), proposedProbabilities.end()));
		

		if (TVal < minTVal)break;


		//add point to list and variance
		points.insert(points.begin() + minSection, proposedpoints[minSection]);
		means[minSection] = proposedmeans2[minSection];
		means.insert(means.begin() + minSection, proposedmeans1[minSection]);


		//calculate new proposed point right side
		int newSize = minSection >= points.size() - 1 ? tofit.size() - points[minSection] : points[minSection + 1] - points[minSection];//If its the last step go to the end of data
		findstepTTest(&tofit[points[minSection]], newSize, mean1, mean2, pos, TVal);
		pos += points[minSection];
		proposedpoints[minSection] = pos;
		proposedProbabilities[minSection] = TVal;
		proposedmeans1[minSection] = mean1;
		proposedmeans2[minSection] = mean2;


		//calculate new proposed point left side
		int prevPoint = minSection > 0 ? points[minSection - 1] : 0;
		newSize = points[minSection] - prevPoint;
		findstepTTest(&tofit[prevPoint], newSize, mean1, mean2, pos, TVal);
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