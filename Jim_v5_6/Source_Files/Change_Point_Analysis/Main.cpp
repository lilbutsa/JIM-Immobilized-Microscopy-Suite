
#include <vector>
#include <iostream>     // std::cout
#include <algorithm>    // std::shuffle
#include <array>        // std::array
#include <random>       // std::default_random_engine
#include <chrono>       // std::chrono::system_clock
#include "ipp.h"
#include <numeric>
#include <cstdlib>      // std::rand, std::srand
#include "BLCSVIO.h"

using namespace std;



float cusum(vector<float> datain) {
	float mean, min, max;
	ippsMean_32f(datain.data(), datain.size(), &mean, ippAlgHintFast);
	ippsSubC_32f_I(mean, datain.data(), datain.size());
	std::partial_sum(datain.begin(), datain.end(), datain.begin());
	ippsMinMax_32f(datain.data(), datain.size(), &min, &max);

	return (max - min);

}

float stepprob(vector<float> datain, int numofbootstraps) {
	float sdiff0;
	int lowerrand;

	sdiff0 = cusum(datain);

	lowerrand = 0;

	// obtain a time-based seed:
	unsigned seed = std::chrono::system_clock::now().time_since_epoch().count();


	for (int i = 0; i < numofbootstraps; i++) {
		shuffle(datain.begin(), datain.end(), std::default_random_engine(seed));
		if (cusum(datain) < sdiff0)lowerrand++;
	}

	return (float)lowerrand / (float)numofbootstraps;

}

int findstep(vector<float> datain) {
	vector<float> datastep;
	float mean1, mean2, minrms = FLT_MAX, rms;
	int vecsize = datain.size(), minrmspos;
	for (int i = 1; i < datain.size() - 1; i++) {
		datastep = datain;
		ippsMean_32f(datastep.data(), i, &mean1, ippAlgHintFast);
		ippsMean_32f(&datastep[i], vecsize - i, &mean2, ippAlgHintFast);
		ippsSubC_32f_I(mean1, datastep.data(), i);
		ippsSubC_32f_I(mean2, &datastep[i], vecsize - i);
		ippsDotProd_32f(datastep.data(), datastep.data(), vecsize, &rms);
		if (rms < minrms) {
			minrms = rms;
			minrmspos = i;
		}
	}
	return minrmspos;
}


void ChangePointAnalysis(vector<float>& mydata, double threshold, vector<int>& steps, vector<float>& stepheights, int iterations)
{
	steps.resize(2);
	vector<int> toerase;
	steps[0] = 0;
	steps[1] = mydata.size() - 1;
	int numofsteps;


	bool solrunning = true;

	while (solrunning) {
		solrunning = false;
		numofsteps = steps.size();
		for (int i = 0; i < numofsteps - 1; i++) {
			if (1 - stepprob(vector<float>(&mydata[steps[i]], &mydata[steps[i + 1] - 1]), iterations) < threshold) {
				steps.push_back(findstep(vector<float>(&mydata[steps[i]], &mydata[steps[i + 1] - 1])) + steps[i]);
				solrunning = true;
			}
		}
		sort(steps.begin(), steps.end());


		for (int i = 0; i < steps.size() - 2; i++) {
			if (1 - stepprob(vector<float>(&mydata[steps[i]], &mydata[steps[i + 2] - 1]), iterations) > threshold) {
				toerase.push_back(i + 1);
				solrunning = true;
			}
		}
		for (int i = 0; i < toerase.size(); i++)steps.erase(steps.begin() + toerase[toerase.size() - 1 - i]);
		toerase.clear();
	}

	stepheights.resize(steps.size() - 1);
	for (int i = 0; i<steps.size() - 1; i++)ippsMean_32f(&mydata[steps[i]], steps[i + 1] - steps[i], &stepheights[i], ippAlgHintFast);

	steps.erase(steps.end() - 1);
	steps.erase(steps.begin());

}

int main(int argc, char *argv[])
{
	double threshold = 0.05;
	int iterations = 1000;
	bool bmultistepfit = true;

	if (argc < 3) { std::cout << "could not read file name" << endl; return 1; }
	std::string inputfile = argv[1];
	std::string output = argv[2];

	for (int i = 1; i < argc; i++) {
		if (std::string(argv[i]) == "-Threshold") {
			if (i + 1 < argc) {
				threshold = stod(argv[i + 1]);
				cout << "Threshold set to " << threshold << endl;
			}
			else { std::cout << "error inputting threshold" << std::endl; return 1; }
		}
		if (std::string(argv[i]) == "-Iterations") {
			if (i + 1 < argc) {
				iterations = stoi(argv[i + 1]);
				cout << "Iterations set to " << iterations << endl;
			}
			else { std::cout << "error inputting number of iterations" << std::endl; return 1; }
		}
		if (std::string(argv[i]) == "-FitSingleSteps") {
			bmultistepfit = false;
			cout << "Fitting Singe Steps\n";
		}
	}

	std::vector<std::vector<float>> alltofit(3000, vector<float>(1000, 0));
	BLCSVIO::readVariableWidthCSV(inputfile, alltofit);

	if (bmultistepfit) {
		vector<vector<int>> steps(alltofit.size());;
		vector<vector<float>> stepheights(alltofit.size());
		for (int i = 0; i < alltofit.size(); i++)ChangePointAnalysis(alltofit[i], threshold, steps[i], stepheights[i], iterations);
		for (int i = 0; i < steps.size(); i++)if (steps[i].size() == 0)steps[i].push_back(0);
		BLCSVIO::writeCSV(output + "_Frame_of_Steps.csv", steps, "Each value is the first frame of that step starting from 0\n");
		BLCSVIO::writeCSV(output + "_Step_Heights.csv", stepheights, "Each value is height of each step\n");
	}
	else {
		vector<vector<float>> onestepresults(alltofit.size(), vector<float>(7, 0.0));
		for (int i = 0; i < alltofit.size(); i++) {
			onestepresults[i][0] = i + 1;
			int steppos;
			ippsMean_32f(alltofit[i].data(), alltofit[i].size(), &onestepresults[i][1], ippAlgHintFast);
			onestepresults[i][2] = stepprob(alltofit[i], iterations);
			steppos = findstep(alltofit[i]);
			onestepresults[i][3] = (float)steppos;
			ippsMean_32f(alltofit[i].data(), steppos, &onestepresults[i][4], ippAlgHintFast);
			ippsMean_32f(&alltofit[i][steppos], alltofit[i].size() - steppos, &onestepresults[i][5], ippAlgHintFast);

			ippsSubC_32f_I(onestepresults[i][4], alltofit[i].data(), steppos);
			ippsSubC_32f_I(onestepresults[i][5], &alltofit[i][steppos], alltofit[i].size()-steppos);
			onestepresults[i][6] = stepprob(alltofit[i], iterations);

		}
		BLCSVIO::writeCSV(output + "_Single_Step_Fits.csv", onestepresults, "Trace Number, No step mean,One or more Step Probability,Step Position, Initial Mean, Final Mean, Probability of more steps \n");
	}


	//system("PAUSE");
}




