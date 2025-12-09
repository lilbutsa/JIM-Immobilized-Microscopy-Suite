#include <vector>
#include <numeric>
#include <functional>
#include <algorithm>

void findstepL2(double* datain, size_t vecsize, double& mean1, double& mean2, double& L2_1, double& L2_2, int& pos) {
	
	if (vecsize < 2) {
		mean1 = datain[0];
		mean2 = datain[0];
		L2_1 = DBL_MAX / 1000;
		L2_2 = DBL_MAX / 1000;
		pos = 1;
		return;
	}
	double diff1, diff2, mean1in, mean2in, L2in1 = 0, L2in2 = 0, minVar = DBL_MAX;
	std::vector<double> dataMeanSubtracted(vecsize);
	mean2in = std::accumulate(datain, datain + vecsize, 0.0);
	mean2in = mean2in / vecsize;
	std::transform(datain, datain + vecsize, dataMeanSubtracted.begin(), [mean2in](auto x) { return x - mean2in; });

	mean1in = 0;

	for (int i = 0; i < vecsize - 1; i++) {
		dataMeanSubtracted[i] = dataMeanSubtracted[i] - mean1in + mean2in;
		diff1 = (mean1in * i + datain[i]) / (i + 1) - mean1in;
		mean1in += diff1;
		diff2 = (mean2in * (vecsize - i) - datain[i]) / (vecsize - i - 1) - mean2in;
		mean2in += diff2;

		std::transform(dataMeanSubtracted.data(), dataMeanSubtracted.data() + i + 1, dataMeanSubtracted.data(), [diff1](auto x) { return x - diff1; });
		std::transform(&dataMeanSubtracted[i + 1], &dataMeanSubtracted[i + 1] + vecsize - i - 1, &dataMeanSubtracted[i + 1], [diff2](auto x) { return x - diff2; });

		L2in1 = std::inner_product(dataMeanSubtracted.data(), dataMeanSubtracted.data()+i+1, dataMeanSubtracted.data(), 0.0);
		L2in2 = std::inner_product(&dataMeanSubtracted[i + 1], &dataMeanSubtracted[i + 1]+ vecsize - i - 1, & dataMeanSubtracted[i + 1], 0.0);


		if (L2in1 + L2in2 < minVar) {
			L2_1 = L2in1;
			L2_2 = L2in2;
			minVar = L2_1 + L2_2;
			pos = i + 1;
			mean1 = mean1in;
			mean2 = mean2in;
		}	
	}
}


void findstepTTest(double* datain, int vecsize, double& mean1, double& mean2, int& pos, double& maxTVal) {

	double diff1, diff2, mean1in,mean2in, L2in1 = 0, L2in2 = 0, tVal;
	int length1, length2;
	std::vector<double> dataMeanSubtracted(vecsize);
	mean2in = std::accumulate(datain, datain + vecsize, 0.0);
	mean2in = mean2in / vecsize;
	std::transform(datain, datain + vecsize, dataMeanSubtracted.begin(), [mean2in](auto x) { return x - mean2in; });

	maxTVal = 0;
	mean1in = 0;

	for (int i = 0; i < vecsize - 1; i++) {
		dataMeanSubtracted[i] = dataMeanSubtracted[i] - mean1in + mean2in;
		diff1 = (mean1in * i + datain[i]) / (i + 1) - mean1in;
		mean1in += diff1;
		diff2 = (mean2in * (vecsize - i) - datain[i]) / (vecsize - i - 1) - mean2in;
		mean2in += diff2;

		std::transform(dataMeanSubtracted.data(), dataMeanSubtracted.data() + i + 1, dataMeanSubtracted.data(), [diff1](auto x) { return x - diff1; });
		std::transform(&dataMeanSubtracted[i + 1], &dataMeanSubtracted[i + 1] + vecsize - i - 1, &dataMeanSubtracted[i + 1], [diff2](auto x) { return x - diff2; });

		L2in1 = std::inner_product(dataMeanSubtracted.data(), dataMeanSubtracted.data() + i + 1, dataMeanSubtracted.data(), 0.0);
		L2in2 = std::inner_product(&dataMeanSubtracted[i + 1], &dataMeanSubtracted[i + 1] + vecsize - i - 1, &dataMeanSubtracted[i + 1], 0.0);


		length1 = i + 1;
		length2 = vecsize - (i + 1);

		tVal = (L2in1 + L2in2) / (length1 + length2 - 2);
		tVal = abs(mean1in - mean2in) / sqrt(tVal / length1 + tVal / length2);

		if (tVal > maxTVal) {
			maxTVal = tVal;
			pos = i + 1;
			mean1 = mean1in;
			mean2 = mean2in;
		}

	}
}


double calculateL2(double* datain, int vecsize,double& mean) {
	double var = 0;
	std::vector<double> datastep(datain, datain + vecsize);
	mean = std::accumulate(datain, datain + vecsize, 0.0);
	mean = mean / vecsize;
	std::transform(datastep.begin(), datastep.end(), datastep.begin(), [mean](auto x) { return x - mean; });
	return std::inner_product(datastep.begin(), datastep.end(), datastep.begin(), 0.0);
}