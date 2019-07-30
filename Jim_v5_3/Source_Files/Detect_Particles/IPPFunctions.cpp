#include "ipp.h"
#include <string>
#include <iostream>
#include <vector>
#include <algorithm>

#define SQUARE(x) ((x)*(x))

using namespace std;

void convertlabelledtopositions(std::vector<int>& labelled, int& numfound, std::vector<std::vector<int>>& labelledpos) {

	std::vector<std::vector<int>>pos(numfound);
	labelledpos.clear();

	int imagesize = labelled.size();

	for (int i = 0; i < imagesize; i++)if (labelled[i]>0.5)
		pos[labelled[i] - 1].push_back(i);
	for (int i = 0; i < pos.size(); i++)if (pos[i].size()>5)
		labelledpos.push_back(pos[i]);

	int imin, imax;
	std::vector<int>close, far;
	for (int i = 0; i < labelledpos.size(); i++) {
		ippsMinMax_32s(&labelledpos[i][0], labelledpos[i].size(), &imin, &imax);
		if (imax - imin > 0.4*imagesize) {
			close.clear();
			far.clear();
			for (int j = 0; j < labelledpos[i].size(); j++)
				if (labelledpos[i][0] - labelledpos[i][j] < 0.4*imagesize)
					close.push_back(labelledpos[i][j]);
				else far.push_back(labelledpos[i][j]);
				labelledpos[i] = close;
				labelledpos.push_back(far);
		}
	}
}

void FindCentroids(std::vector<std::vector<int>>& pos2 /*positions vector*/, int imagewidth, std::vector<std::vector<float>> & centroids) {
	centroids.clear();
	std::vector<float> xpos, ypos, newvec(2);//x centre, ycentre,eccentricity,length,x vec,yvec of major axis
	for (int i = 0; i < pos2.size(); i++) {
		xpos.resize(pos2[i].size());
		ypos.resize(pos2[i].size());
		for (int j = 0; j < pos2[i].size(); j++) {
			xpos[j] = pos2[i][j] % imagewidth; ypos[j] = (int)(pos2[i][j] / imagewidth);
		}
		ippsMean_32f(&xpos[0], xpos.size(), &newvec[0], ippAlgHintFast);
		ippsMean_32f(&ypos[0], ypos.size(), &newvec[1], ippAlgHintFast);
		centroids.push_back(newvec);
	}

}

float FindMaxDistFromLinear(float& xcent, float& ycent, float& xvec, float& yvec, vector<float>& xposvec, vector<float>& yposvec) {
	float x1, y1, x2, y2, xin, yin;
	float max, dist, denom, maxdist = 0;

	x1 = xcent;
	y1 = ycent;
	x2 = xcent + xvec;
	y2 = ycent + yvec;
	denom = sqrt(SQUARE(y2 - y1) + SQUARE(x2 - x1));
	max = 0;
	for (int j = 0; j < xposvec.size(); j++)
	{
		xin = xposvec[j]; yin = yposvec[j];
		dist = abs((y2 - y1)*xin - (x2 - x1)*yin + x2*y1 - y2 * x1) / denom;
		if (dist > maxdist)maxdist = dist;
	}

	return maxdist;
}


void componentMeasurements(std::vector<std::vector<int>>& pos2 /*positions vector*/, int imagewidth, std::vector<std::vector<float>> & measurementresults, std::vector<float> & imagef) {
	measurementresults.clear();
	std::vector<float> xpos, ypos, newvec(14);//x centre, ycentre,eccentricity,length,x vec,yvec of major axis,count, xmax pos, y max pos, maxdistfromlinear, x min, x max, y min, y max
	IppiSize roiSize2;
	double x2, y2, xy;
	float max, max2;
	int maxpos;
	for (int i = 0; i < pos2.size(); i++) {
		xpos.resize(pos2[i].size());
		ypos.resize(pos2[i].size());
		for (int j = 0; j < pos2[i].size(); j++) {
			xpos[j] = pos2[i][j] % imagewidth; ypos[j] = (int)(pos2[i][j] / imagewidth);
		}
		ippsMean_32f(&xpos[0], xpos.size(), &newvec[0], ippAlgHintFast);
		ippsMean_32f(&ypos[0], ypos.size(), &newvec[1], ippAlgHintFast);
		ippsSubC_32f_I(newvec[0], &xpos[0], xpos.size());
		ippsSubC_32f_I(newvec[1], &ypos[0], xpos.size());
		roiSize2 = { (int)xpos.size(), 1 };
		ippiDotProd_32f64f_C1R(&xpos[0], sizeof(float), &xpos[0], sizeof(float), roiSize2, &x2, ippAlgHintFast);
		ippiDotProd_32f64f_C1R(&ypos[0], sizeof(float), &ypos[0], sizeof(float), roiSize2, &y2, ippAlgHintFast);
		ippiDotProd_32f64f_C1R(&xpos[0], sizeof(float), &ypos[0], sizeof(float), roiSize2, &xy, ippAlgHintFast);
		x2 /= xpos.size();
		y2 /= xpos.size();
		xy /= xpos.size();

		newvec[2] = (x2 + y2) / 2 + sqrt(4 * xy*xy + (x2 - y2)*(x2 - y2)) / 2;
		newvec[3] = (x2 + y2) / 2 - sqrt(4 * xy*xy + (x2 - y2)*(x2 - y2)) / 2;

		if (xy != 0) { newvec[4] = newvec[2] - y2; newvec[5] = xy; }
		else { if (y2 == 0) { newvec[4] = 1; newvec[5] = 0; } else { newvec[4] = 0; newvec[5] = 1; } }

		newvec[2] = 1 - sqrt(newvec[3]) / sqrt(newvec[2]);

		ippsMaxAbs_32f(&xpos[0], xpos.size(), &max);
		ippsMaxAbs_32f(&ypos[0], ypos.size(), &max2);
		newvec[3] = sqrt(max*max + max2*max2);

		float norm = sqrt(newvec[4] * newvec[4] + newvec[5] * newvec[5]);
		newvec[4] = newvec[4] / norm;
		newvec[5] = newvec[5] / norm;

		if (newvec[4] < 0) {
			newvec[4] *= -1.0; newvec[5] *= -1.0;
		}


		newvec[6] = xpos.size();
		//for (int k = 0; k < 6; k++)cout << newvec[k] << " ";
		//cout << endl;


		max = 0;
		maxpos = 0;
		for (int j = 0; j < pos2[i].size(); j++) {
			if (imagef[pos2[i][j]] > max) {
				max = imagef[pos2[i][j]];
				maxpos = pos2[i][j];
			}
		}

		newvec[7] = maxpos % imagewidth;
		newvec[8] = (int)(maxpos / imagewidth);

		for (int j = 0; j < pos2[i].size(); j++) {
			xpos[j] = pos2[i][j] % imagewidth; ypos[j] = (int)(pos2[i][j] / imagewidth);
		}
		newvec[9] = FindMaxDistFromLinear(newvec[0], newvec[1], newvec[4], newvec[5], xpos, ypos);


		ippsMin_32f(&xpos[0], xpos.size(), &max);
		newvec[10] = max;
		ippsMax_32f(&xpos[0], xpos.size(), &max);
		newvec[11] = max;
		ippsMin_32f(&ypos[0], xpos.size(), &max);
		newvec[12] = max;
		ippsMax_32f(&ypos[0], xpos.size(), &max);
		newvec[13] = max;

		measurementresults.push_back(newvec);
	}

}