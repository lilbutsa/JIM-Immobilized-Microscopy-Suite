
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

std::random_device rdev;
std::mt19937 rgen(rdev());

uint32_t random_bounded(uint32_t range) {
	uint64_t random32bit = rgen(); //32-bit random number 
	uint64_t  multiresult = random32bit * range;
	return multiresult >> 32;
}


template <class T>
void  myshuffle(T *storage, uint32_t size) {
	for (uint32_t i = size; i>1; i--) {
		uint32_t nextpos = random_bounded(i);
		std::swap(storage[i - 1], storage[nextpos]);
	}
}

void makeStepFitVector(vector<float>& datain, vector<int>& steps, vector<float>& stepfitvector) {
	stepfitvector.resize(datain.size());
	float mean;
	for (int i = 0; i < steps.size() - 1; i++) {
		ippsMean_32f(&datain[steps[i]], steps[i+1]-steps[i], &mean, ippAlgHintFast);
		for (int j = steps[i]; j < steps[i + 1]; j++)stepfitvector[j] = mean;
	}
}

float cusum(vector<float> datain) {
	float min, max;
		std::partial_sum(datain.begin(), datain.end(), datain.begin());
		ippsMinMax_32f(datain.data(), datain.size(), &min, &max);
	return (max - min);

}

float stepprob(vector<float> datain, int numofbootstraps) {
	float sdiff0,mean;
	int lowerrand;

	ippsMean_32f(datain.data(), datain.size(), &mean, ippAlgHintFast);
	ippsSubC_32f_I(mean, datain.data(), datain.size());

	sdiff0 = cusum(datain);

	lowerrand = 0;

	// obtain a time-based seed:
	unsigned seed = std::chrono::system_clock::now().time_since_epoch().count();

	for (int i = 0; i < numofbootstraps; i++) {
			myshuffle(datain.data(), datain.size());
			//shuffle(datain.begin(), datain.end(), std::default_random_engine(seed));
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


void ChangePointAnalysis(vector<float>& mydata, double threshold, vector<float>& stepFitVec, int iterations)
{
	vector<int>steps(2);
	steps[0] = 0;
	steps[1] = mydata.size();
	int numofsteps;
	int steppos;
	float stepProb;

	int iterationsused;
	float miniterations;

	stepFitVec.resize(mydata.size());

	vector<float> residuals(mydata.size());

	makeStepFitVector(mydata, steps, stepFitVec);
	ippsSub_32f(stepFitVec.data(), mydata.data(), residuals.data(), mydata.size());
	stepProb = stepprob(residuals, iterations);
	iterationsused = iterations;
	miniterations = 16 * stepProb*(1 - stepProb) / ((stepProb - threshold)*(stepProb - threshold));
	while (iterationsused < miniterations && iterationsused<10000000) {
		if (miniterations > 900000)cout << stepProb << " " << miniterations << " " << iterationsused;
		iterationsused = min((int)(4 * miniterations), 20000000);
		stepProb = stepprob(residuals, iterationsused);
		miniterations = 16 * stepProb*(1 - stepProb) / ((stepProb - threshold)*(stepProb - threshold));
	}


	while (stepProb > threshold) {
		steps.push_back( findstep(residuals));
		sort(steps.begin(), steps.end());
		makeStepFitVector(mydata, steps, stepFitVec);
		ippsSub_32f(stepFitVec.data(), mydata.data(), residuals.data(), mydata.size());
		stepProb = stepprob(residuals, iterations);
		iterationsused = iterations;
		miniterations = 16 * stepProb*(1 - stepProb) / ((stepProb - threshold)*(stepProb - threshold));
		while (iterationsused < miniterations && iterationsused<10000000) {
			if (miniterations > 900000)cout << stepProb << " " << miniterations << " " << iterationsused;
			iterationsused = min((int)(4 * miniterations), 20000000);
			stepProb = stepprob(residuals, iterationsused);
			miniterations = 16 * stepProb*(1 - stepProb) / ((stepProb - threshold)*(stepProb - threshold));
		}
	}

}

void ChangePointAnalysisIndStepDist(vector<float>& mydata, double threshold, vector<int>& steps, vector<float>& stepheights, int iterations)
{
	steps.resize(2);
	vector<int> toerase;
	steps[0] = 0;
	steps[1] = mydata.size();
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
	bool bIndStepDist = false;

	if (argc < 3) { std::cout << "could not read file name" << endl; return 1; }
	std::string inputfile = argv[1];
	std::string output = argv[2];

	cout << "Set Fitting File " << inputfile << "\n";

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
			cout << "Fitting Single Steps\n";
		}
		if (std::string(argv[i]) == "-IndStepDist") {
			bIndStepDist = true;
			cout << "Fitting Using separate distribution estimates for each step\n";
		}
	}

	std::vector<std::vector<float>> alltofit(3000, vector<float>(1000, 0));
	BLCSVIO::readVariableWidthCSV(inputfile, alltofit);

	if (bIndStepDist && bmultistepfit) {

		vector<vector<int>> steps(alltofit.size());;
		vector<vector<float>> stepheights(alltofit.size());
		for (int i = 0; i < alltofit.size(); i++)ChangePointAnalysisIndStepDist(alltofit[i], threshold, steps[i], stepheights[i], iterations);
		for (int i = 0; i < steps.size(); i++)if (steps[i].size() == 0)steps[i].push_back(0);
		BLCSVIO::writeCSV(output + "_Frame_of_Steps.csv", steps, "Each value is the first frame of that step starting from 0\n");
		BLCSVIO::writeCSV(output + "_Step_Heights.csv", stepheights, "Each value is height of each step\n");

	} else if (bmultistepfit) {
		vector< vector<float> > allStepFits(alltofit.size(), vector<float>(alltofit[0].size()));
		for (int i = 0; i < alltofit.size(); i++) {
			ChangePointAnalysis(alltofit[i], threshold, allStepFits[i], iterations);
			cout << "Fitting Trace " << i + 1 << "\n";
		}
		BLCSVIO::writeCSV(output + "_Step_Fits.csv", allStepFits, "Each row is a particle. Each column is a Frame. Values are the stepfit intensity\n");
	}
	else {
		float stddev;
		vector<vector<float>> onestepresults(alltofit.size(), vector<float>(8, 0.0));
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
			ippsStdDev_32f(alltofit[i].data(), alltofit[i].size(), &stddev, ippAlgHintFast);
			onestepresults[i][7] = stddev;
		}
		BLCSVIO::writeCSV(output + "_Single_Step_Fits.csv", onestepresults, "Trace Number, No step mean,One or more Step Probability,Step Position, Initial Mean, Final Mean, Probability of more steps,Residual Standard Deviation \n");
	}


	//system("PAUSE");
}




