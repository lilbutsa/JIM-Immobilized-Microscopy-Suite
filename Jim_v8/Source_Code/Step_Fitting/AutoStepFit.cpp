
#include <vector>
#include <iostream>     // std::cout
#include "findStepHeader.hpp"




void autoStepFinder(std::vector<double> tofit, int maxSteps, std::vector<int>& fitPoints, std::vector<double>& fitMeans) {
	std::vector<std::vector<int>> savedpoints(maxSteps+1);
	std::vector<std::vector<double>> savedmeans(maxSteps+1);

	std::vector <int> points, proposedpoints;
	std::vector<double> variance, proposedvar1, proposedvar2, counterVar, totalS, questionableTransformedS, means, proposedmeans1, proposedmeans2;

	double var1 = 0, var2 = 0,mean1,mean2, initialVariance;
	int pos = 0;

	//initialise point list and variance
	initialVariance = calculateL2(&tofit[0], tofit.size(),mean1);
	variance.push_back(initialVariance);
	means.push_back(mean1);
	savedmeans[0] = means;


	//initilise proposed points and variance
	findstepL2(tofit.data(), tofit.size(), mean1,mean2, var1, var2, pos);
	proposedpoints.push_back(pos);
	proposedvar1.push_back(var1);
	proposedvar2.push_back(var2);
	proposedmeans1.push_back(mean1);
	proposedmeans2.push_back(mean2);

	//initialise counter variance, total counter variance
	counterVar.push_back(var1); counterVar.push_back(var2);

	totalS.push_back((var1 + var2) / initialVariance);

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
		int newSize = minSection >= points.size() - 1 ? tofit.size() - points[minSection] : points[minSection + 1] - points[minSection];//If its the last step go to the end of data
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


		//calculate new counter variance
		//left
		prevPoint = minSection > 0 ? proposedpoints[minSection - 1] : 0;
		newSize = proposedpoints[minSection] - prevPoint;
		counterVar[minSection] = calculateL2(&tofit[prevPoint], newSize,mean1);
		//right
		newSize = minSection + 1 >= proposedpoints.size() - 1 ? tofit.size() - proposedpoints[minSection + 1] : proposedpoints[minSection + 2] - proposedpoints[minSection + 1];//If its the last step go to the end of data
		counterVar[minSection + 1] = calculateL2(&tofit[proposedpoints[minSection + 1]], newSize,mean1);
		//middle
		counterVar.insert(counterVar.begin() + minSection + 1, calculateL2(&tofit[proposedpoints[minSection]], proposedpoints[minSection + 1] - proposedpoints[minSection],mean1));


		//save variance and counter variance
		var1 = 0; var2 = 0;
		for (int i = 0; i < variance.size(); i++)var1 += variance[i];
		for (int i = 0; i < counterVar.size(); i++)var2 += counterVar[i];
		totalS.push_back(var2 / var1);

		savedpoints[stepCount+1] = points;
		savedmeans[stepCount+1] = means;

	}

	/*cout << "S vals = ";
	for (int i = 0; i < totalS.size(); i++)cout << totalS[i] << " ";
	cout << "\n";
	*/

	//Do the dodgy transform 
	questionableTransformedS = totalS;
	for (int i = 0; i < totalS.size(); i++)questionableTransformedS[i] = totalS[i] - i * (totalS[totalS.size() - 1] - 1) / (totalS.size() - 1) - 1;

	/*cout << "S* vals = ";
	for (int i = 0; i < totalS.size(); i++)cout << quationableTransformedS[i] << " ";
	cout << "\n";
	*/

	int maxPos = std::distance(questionableTransformedS.begin(), std::max_element(questionableTransformedS.begin(), questionableTransformedS.end()));

	//std::cout << "auto = " << maxPos <<" "<< questionableTransformedS.size()<< " " << savedpoints.size() << " " << savedmeans.size() << "\n";

	fitPoints = savedpoints[maxPos];
	fitPoints.insert(fitPoints.begin(), 0);
	fitMeans = savedmeans[maxPos];

}







