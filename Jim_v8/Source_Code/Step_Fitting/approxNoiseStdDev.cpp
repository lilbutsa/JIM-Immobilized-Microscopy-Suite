#include <algorithm>
#include <cmath>
#include<vector>



double approxNoiseStdDev(std::vector<std::vector<double>> dataIn) {//Median absolute deviation

	std::vector<double> allDiffs;

	for (int i = 0; i < dataIn.size(); i++)for (int j = 0; j < dataIn[i].size() - 1; j++)allDiffs.push_back(abs(dataIn[i][j] - dataIn[i][j + 1]));

	size_t n = allDiffs.size() / 2;
	std::nth_element(allDiffs.begin(), allDiffs.begin() + n, allDiffs.end());
	double myMedian =  allDiffs[n];

	//Mad scale factor = 1.4826, Data diff to raw data std dev = 1/Sqrt(2)
	const double scaleFactor = 1.04836;

	return myMedian * scaleFactor;

}
