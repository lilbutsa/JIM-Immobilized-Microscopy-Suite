#include <vector>
#include <iostream>     // std::cout
#include <random>       // std::default_random_engine
#include <chrono>       // std::chrono::system_clock
#include "BLCSVIO.h"
#include "../findStepHeader.hpp"


int Step_Fitting(std::string output, std::string inputfile, double TThreshold, int maxSteps, int method);


double erfinv(double x);
void testCase(int steps, int frames, double noise);

int main(int argc, char* argv[])
{
	
	int method = 0;

	double TThreshold = 50;
	double threshold = erf(TThreshold);
	int iterations = 1000;
	int maxSteps = -1;


	if (argc < 3) { std::cout << "could not read file name\n"; return 1; }
	std::string inputfile = argv[1];
	std::string output = argv[2];

	std::cout << "Step-Fitting File " << inputfile << "\n";

	for (int i = 1; i < argc; i++) {
		if (std::string(argv[i]) == "-TThreshold") {
			if (i + 1 < argc) {
				TThreshold = std::stod(argv[i + 1]);
				threshold = erf(threshold);
				std::cout << "T value threshold set to "<<TThreshold<<" corresponding to P value = " << 1-threshold << "\n";
			}
			else { std::cout << "error inputting t value threshold\n"; return 1; }
		}
		if (std::string(argv[i]) == "-MaxSteps") {
			if (i + 1 < argc) {
				maxSteps = std::stoi(argv[i + 1]);
				std::cout << "Max Steps set to " << maxSteps << "\n";
			}
			else { std::cout << "error inputting max number of steps\n"; return 1; }
		}
		if (std::string(argv[i]) == "-Iterations") {
			if (i + 1 < argc) {
				iterations = std::stoi(argv[i + 1]);
				std::cout << "Iterations set to " << iterations << "\n";
			}
			else { std::cout << "error inputting number of iterations\n"; return 1; }
		}
		if (std::string(argv[i]) == "-Aggarwal") {
			method = 0; std::cout << "method set to Aggarwal\n";
		}
		if (std::string(argv[i]) == "-TTest") {
			method = 1; std::cout << "method set to T-Test\n";
		}
		if (std::string(argv[i]) == "-AutoStepFit") {
			method = 2; std::cout << "method set to AutoStepFit\n";
		}
		if (std::string(argv[i]) == "-ChangePoint") {
			method = 3; std::cout << "method set to Heuristic Chnage Point Analysis\n";
		}
		
	}

	return Step_Fitting(output, inputfile, TThreshold, maxSteps, method);
	//for (int i = 0; i < 10; i++)for (int j = 0; j < 10; j++)testCase(i, 100, 0.25 * (j+1));
	//system("PAUSE");
}

void testCase(int steps,int frames,double noise) {

	std::default_random_engine generator;
	std::normal_distribution<double> distribution(0, noise);


	std::vector<std::vector<double>> testTraces(100);
	std::vector<double> test(frames);
	for (int j = 0; j < testTraces.size(); j++) {
		for (int i = 0; i < frames; i++) {
			test[i] = round(steps * (i+0.001) / frames) + distribution(generator);
		}
		testTraces[j] = test;
	}


	std::vector<int> fitPoints;
	std::vector<double> fitMeans;

	double stdDev = approxNoiseStdDev(testTraces);

	std::vector<int> counts(4, 0);

	for (int j = 0; j < testTraces.size(); j++) {
		aggarwalStepFit(testTraces[j], 9 * stdDev * stdDev, testTraces[j].size() / 4, fitPoints, fitMeans);
		if (fitMeans.size() == steps+1)counts[0]++;
		autoStepFinder(testTraces[j], testTraces[j].size() / 4, fitPoints, fitMeans);
		if (fitMeans.size() == steps+1)counts[1]++;
		stasiStepFit(testTraces[j], 3, testTraces[j].size() / 4, fitPoints, fitMeans);
		if (fitMeans.size() == steps+1)counts[2]++;
		//heuristicChangePointStepFit(testTraces[j], 0.95, 10000, testTraces[j].size() / 4, fitPoints, fitMeans);
		if (fitMeans.size() == steps+1)counts[3]++;
		/*std::cout << "my steps = " << fitPoints.size() << " positions = ";
		for (int i = 0; i < fitPoints.size(); i++)std::cout << " "<<fitPoints[i];
		std::cout << " heights = ";
		for (int i = 0; i < fitMeans.size(); i++)std::cout << " " << fitMeans[i];
		std::cout<<"\n";*/
	}
	std::cout <<"steps = "<<steps<<" noise = "<<noise<<" counts = ";
	for (int i = 0; i < counts.size(); i++)std::cout << " " << counts[i];
	std::cout << "\n";

}