#include "ipp.h"
#include <string>
#include <iostream>
#include <vector>
#include <algorithm>
#include <cmath>
#include <float.h>

#define SQUARE(x) ((x)*(x))

using namespace std;

void convertlabelledtopositions(std::vector<int>& labelled, int& numfound, std::vector<std::vector<int> >& labelledpos) {

	std::vector<std::vector<int> >pos(numfound);
	labelledpos.clear();

	int imagesize = labelled.size();

	for (int i = 0; i < imagesize; i++)if (labelled[i]>0.5)
		pos[labelled[i] - 1].push_back(i);
	for (int i = 0; i < pos.size(); i++)if (pos[i].size()>3)
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

void FindCentroids(std::vector<std::vector<int> >& pos2 /*positions vector*/, int imagewidth, std::vector<std::vector<float> > & centroids) {
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


void componentMeasurements(std::vector<std::vector<int> >& pos2 /*positions vector*/, int imagewidth, std::vector<std::vector<float> > & measurementresults, std::vector<float> & imagef) {
	measurementresults.clear();
	std::vector<float> xpos, ypos, newvec(18);//x centre, ycentre,eccentricity,length,x vec,yvec of major axis,count, xmax pos, y max pos, maxdistfromlinear, x end 1, y end 1, x end 2, y end 2,X bounding Box Min, X Bounding Box Max,Y bounding Box Min, Y Bounding Box Max
	std::vector<float> vx2, vy2;
	IppiSize roiSize2;
	double x2, y2, xy;
	float max, max2, min;
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
		else { if (y2 == 0) { newvec[4] = 0; newvec[5] = 1; } else { newvec[4] = 1; newvec[5] = 0; } }

		newvec[2] = 1 - sqrt(newvec[3]) / sqrt(newvec[2]);

		float norm = sqrt(newvec[4] * newvec[4] + newvec[5] * newvec[5]);
		newvec[4] = newvec[4] / norm;
		newvec[5] = newvec[5] / norm;

		if (newvec[4] < 0) {
			newvec[4] *= -1.0; newvec[5] *= -1.0;
		}

		vx2.resize(pos2[i].size());
		vy2.resize(pos2[i].size());
		float vx = newvec[4], vy = newvec[5];
		ippsMulC_32f(xpos.data(), vx, vx2.data(), xpos.size());
		ippsMulC_32f(ypos.data(), vy, vy2.data(), ypos.size());
		ippsAdd_32f_I(vy2.data(), vx2.data(), vx2.size());
		ippsMinMax_32f(vx2.data(), vx2.size(), &min, &max);

		newvec[3] = max - min;

		newvec[10] = newvec[0] + vx*min;
		newvec[11] = newvec[1] + vy*min;

		newvec[12] = newvec[0] + vx*max;
		newvec[13] = newvec[1] + vy*max;


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
		newvec[14] = max;
		ippsMax_32f(&xpos[0], xpos.size(), &max);
		newvec[15] = max;
		ippsMin_32f(&ypos[0], xpos.size(), &max);
		newvec[16] = max;
		ippsMax_32f(&ypos[0], xpos.size(), &max);
		newvec[17] = max;


		measurementresults.push_back(newvec);
	}

}

float pointsNearestNeighbour(std::vector<int>& points1, std::vector<int>& points2, int imagewidth) {

	int len1 = points1.size();
	int len2 = points2.size();

	std::vector<float> xpos1(len1), ypos1(len1), xpos2(len2), ypos2(len2),working(len2),working2(len2);

	float mindist = FLT_MAX,minin;


	for (int j = 0; j < len1; j++) {
		xpos1[j] = points1[j] % imagewidth; ypos1[j] = (int)(points1[j] / imagewidth);
	}

	for (int j = 0; j < len2; j++) {
		xpos2[j] = points2[j] % imagewidth; ypos2[j] = (int)(points2[j] / imagewidth);
	}

	//cout << xpos1[0] << " " << ypos1[0] << " " << xpos2[0] << " " << ypos2[0] << "\n";

	for (int i = 0; i < len1; i++) {
		//find distance between centroids
		ippsAddC_32f(xpos2.data(), -xpos1[i], working.data(), len2);
		ippsAddC_32f(ypos2.data(), -ypos1[i], working2.data(), len2);

		ippsSqr_32f_I(working.data(), len2);
		ippsSqr_32f_I(working2.data(), len2);
		ippsAdd_32f_I(working2.data(), working.data(), len2);

		ippsMin_32f(working.data(), len2, &minin);

		if (minin < mindist)mindist = minin;
	}

	return sqrt(mindist);

}

void nearestNeighbour(std::vector<std::vector<float> >& centroidresults,std::vector<std::vector<int> >& pos2 /*positions vector*/, int imagewidth, std::vector<float>& nearestNeighbourVec) {

	int len = centroidresults.size();
	nearestNeighbourVec.resize(len);


	std::vector<float> xval(len), yval(len) , roiLen(len), working(len), working2(len);

	std::vector<int> minDistIndex(len);

	for (int i = 0; i < len; i++) {
		xval[i] = centroidresults[i][0];
		yval[i] = centroidresults[i][1];
		roiLen[i] = -0.5*centroidresults[i][3];
	}

	for (int i = 0; i < len; i++) {
		//find distance between centroids
		ippsAddC_32f(xval.data(), -xval[i], working.data(), len);
		ippsAddC_32f(yval.data(), -yval[i], working2.data(), len);

		ippsSqr_32f_I(working.data(), len);
		ippsSqr_32f_I(working2.data(), len);
		ippsAdd_32f_I(working2.data(), working.data(), len);

		ippsSqrt_32f_I(working.data(), len);

		//subtract radius
		ippsAdd_32f_I(roiLen.data(), working.data(), len);

		working[i] = FLT_MAX;

		//ippsMin_32f(working.data(), len, &nearestNeighbourVec[i]);
		//nearestNeighbourVec[i] += roiLen[i];

		ippsSortIndexAscend_32f_I(working.data(), minDistIndex.data(), len);


		nearestNeighbourVec[i] = pointsNearestNeighbour(pos2[i], pos2[minDistIndex[0]], imagewidth);
		//cout << "first time " << i << " " << minDistIndex[0] << " " << xval[i]<< " " << yval[i] << " " << xval[minDistIndex[0]]<< " " << yval[minDistIndex[0]]<< " " << working[0] + roiLen[i]<< " " << nearestNeighbourVec[i]<<"\n";
		int count = 1;
		while (working[count]+ roiLen[i] < nearestNeighbourVec[i]) {
			float disttest = pointsNearestNeighbour(pos2[i], pos2[minDistIndex[count]], imagewidth);
			//cout << "time " <<count+1<<" = "<< i << " " << minDistIndex[count] << " " << xval[i] << " " << yval[i] << " " << xval[minDistIndex[count]] << " " << yval[minDistIndex[count]] << " " << working[count] + roiLen[i] << " " << disttest << "\n";

			if (disttest < nearestNeighbourVec[i])nearestNeighbourVec[i] = disttest;
			count++;
		}

		//cout << nearestNeighbourVec[i] << " " << working[1] + roiLen[i] << "\n";
	}

}