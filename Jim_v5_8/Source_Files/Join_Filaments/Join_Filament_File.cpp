#include <string>
#include <iostream>
#include <vector>
#include <algorithm>
#include <cmath>
#include "BLTiffIO.h"
#include "BLCSVIO.h"
#include "ipp.h"

#define SQUARE(x) ((x)*(x))



using namespace std;

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

bool greater_than_length(const std::pair <std::vector<float>, std::vector<int> >& vec1, const std::pair <std::vector<float>, std::vector<int> >& vec2){
		return ((vec1.first)[3] > (vec2.first)[3]);
};


void joinfragments(std::vector<std::vector<int> >& positions, std::vector<std::vector<float> >& measurements, float maxangle, float maxjoindist, float maxlineenddist, int imagewidth, std::vector<float> & imagef) {
	float centroidx, vectorx, centroidy, vectory, length, endx1, endx2, endy1, endy2;
	float incentroidx, invectorx, incentroidy, invectory, inlength, inendx1, inendx2, inendy1, inendy2;
	float enddist, linepointdist, angle;
	std::vector< std::pair <std::vector<float>, std::vector<int> > > pairMeasPos;
	bool bjointoccurred = true;



	while(bjointoccurred){
		bjointoccurred = false;

		componentMeasurements(positions, imagewidth, measurements, imagef);
		pairMeasPos.clear();
		for (int i = 0; i < positions.size(); i++)pairMeasPos.push_back(make_pair(measurements[i], positions[i]));
		sort(pairMeasPos.begin(), pairMeasPos.end(), greater_than_length);

		for (int i = 0; i < pairMeasPos.size() - 1; i++) {

			vectorx = ((pairMeasPos[i]).first)[4];
			vectory = ((pairMeasPos[i]).first)[5];

			endx1 = ((pairMeasPos[i]).first)[10];
			endy1 = ((pairMeasPos[i]).first)[11];

			endx2 = ((pairMeasPos[i]).first)[12];
			endy2 = ((pairMeasPos[i]).first)[13];


			for (int j = i + 1; j < pairMeasPos.size(); j++) {

				invectorx = ((pairMeasPos[j]).first)[4];
				invectory = ((pairMeasPos[j]).first)[5];

				inendx1 = ((pairMeasPos[j]).first)[10];
				inendy1 = ((pairMeasPos[j]).first)[11];

				inendx2 = ((pairMeasPos[j]).first)[12];
				inendy2 = ((pairMeasPos[j]).first)[13];

				enddist = min(min(min(SQUARE(endx1 - inendx1) + SQUARE(endy1 - inendy1),
					SQUARE(endx1 - inendx2) + SQUARE(endy1 - inendy2)),
					SQUARE(endx2 - inendx1) + SQUARE(endy2 - inendy1)),
					SQUARE(endx2 - inendx2) + SQUARE(endy2 - inendy2));
				enddist = sqrt(enddist);

				linepointdist = min(abs((endy2 - endy1)*inendx1 - (endx2 - endx1)*inendy1 + endx2 * endy1 - endy2 * endx1) / sqrt(SQUARE(endy2 - endy1) + SQUARE(endx2 - endx1)),
					abs((endy2 - endy1)*inendx2 - (endx2 - endx1)*inendy2 + endx2 * endy1 - endy2 * endx1) / sqrt(SQUARE(endy2 - endy1) + SQUARE(endx2 - endx1)));

				angle = abs(vectorx * invectorx + vectory * invectory);
				if (abs(angle) > 0.99999)angle = 0; else angle = acos(abs(angle));

				if (enddist < maxjoindist && angle < maxangle && linepointdist < maxlineenddist) {
					((pairMeasPos[i]).second).insert((pairMeasPos[i]).second.end(), (pairMeasPos[j]).second.begin(), (pairMeasPos[j]).second.end());
					pairMeasPos.erase(pairMeasPos.begin() + j);
					bjointoccurred = true;
					break;
				}
			}
			if (bjointoccurred)break;
		}

		positions.clear();
		measurements.clear();
		for (int i = 0; i < pairMeasPos.size(); i++) {
			measurements.push_back(pairMeasPos[i].first);
			positions.push_back(pairMeasPos[i].second);
		}

	}

}


/*
void joinfragments(std::vector<std::vector<int> >& initialcullpos, std::vector<std::vector<float> >& icmeasurementresults, float maxangle, float maxjoindist, float maxendline, int imagewidth, std::vector<float> & imagef) {
	std::vector<std::vector<int> > joinedpos;
	float cx, vx, cy, vy, length, endx1, endx2, endy1, endy2, inendx1, inendy1, inendx2, inendy2, enddist, distin, distin2, angle, endline;
	std::vector<std::vector<int> > tojoin(initialcullpos.size());
	for (int i = 0; i < initialcullpos.size(); i++) {
		cx = icmeasurementresults[i][0];
		cy = icmeasurementresults[i][1];
		vx = icmeasurementresults[i][0] + icmeasurementresults[i][4];
		vy = icmeasurementresults[i][1] + icmeasurementresults[i][5];
		length = icmeasurementresults[i][3];


		endx1 = cx + 0.5 * length * vx;
		endy1 = cy + 0.5 * length * vy;

		endx2 = cx - 0.5 * length * vx;
		endy2 = cy - 0.5 * length * vy;

		for (int j = 0; j < initialcullpos.size(); j++)
		{
			inendx1 = icmeasurementresults[j][0] + icmeasurementresults[j][3] * icmeasurementresults[j][4];
			inendy1 = icmeasurementresults[j][1] + icmeasurementresults[j][3] * icmeasurementresults[j][5];

			inendx2 = icmeasurementresults[j][0] - icmeasurementresults[j][3] * icmeasurementresults[j][4];
			inendy2 = icmeasurementresults[j][1] - icmeasurementresults[j][3] * icmeasurementresults[j][5];

			enddist = maxjoindist + 1;
			endline = maxjoindist + 1;

			distin = sqrt(SQUARE(endx1 - inendx1) + SQUARE(endy1 - inendy1));
			distin2 = abs((y2 - y1)*inendx1 - (x2 - x1)*inendy1 + x2*y1 - y2 * x1) / sqrt(SQUARE(y2 - y1) + SQUARE(x2 - x1));
			if (distin < enddist) {
				enddist = distin; endline = distin2;
			}

			distin = sqrt(SQUARE(endx2 - inendx1) + SQUARE(endy2 - inendy1));
			if (distin < enddist) {
				enddist = distin; endline = distin2;
			}

			distin = sqrt(SQUARE(endx1 - inendx2) + SQUARE(endy1 - inendy2));
			distin2 = abs((y2 - y1)*inendx2 - (x2 - x1)*inendy2 + x2*y1 - y2 * x1) / sqrt(SQUARE(y2 - y1) + SQUARE(x2 - x1));
			if (distin < enddist) {
				enddist = distin; endline = distin2;
			}

			distin = sqrt(SQUARE(endx2 - inendx2) + SQUARE(endy2 - inendy2));
			if (distin < enddist) {
				enddist = distin; endline = distin2;
			}



			angle = abs(icmeasurementresults[i][4] * icmeasurementresults[j][4] + icmeasurementresults[i][5] * icmeasurementresults[j][5]);
			if (angle > 0.999)angle = 0; else angle = acos(angle);

			//if (i == j)std::cout << enddist << " " << endline << " " << angle << " " << abs(icmeasurementresults[i][4] * icmeasurementresults[j][4] + icmeasurementresults[i][5] * icmeasurementresults[j][5])<< std::endl;
			//	cout << i << " " << j << " " << x1 << " " << measurementresults[i][4] << " " << y1 << " " << measurementresults[i][5] << " " << measurementresults[j][0] << " " << measurementresults[j][1] << " " <<
			//		sqrt((measurementresults[j][0] - x1)*(measurementresults[j][0] - x1) + (measurementresults[j][1] - y1)*(measurementresults[j][1] - y1)) << " " << abs((y2 - y1)*measurementresults[j][0] - (x2 - x1)*measurementresults[j][1] + x2*y1 - y2 * x1) / sqrt(SQUARE(y2 - y1) + SQUARE(x2 - x1)) << endl;
			//abs((y2 - y1)*icmeasurementresults[j][0] - (x2 - x1)*icmeasurementresults[j][1] + x2*y1 - y2 * x1) / sqrt(SQUARE(y2 - y1) + SQUARE(x2 - x1)) < maxangledist
			if (enddist < maxjoindist &&angle<maxangle&&endline<maxendline)
				tojoin[i].push_back(j);
		}
	}

	std::vector<std::vector<int> > tojoin2;
	int valin;
	bool found = false;
	if (tojoin.size()>0)tojoin2.push_back(tojoin[0]);
	for (int i = 0; i < tojoin.size(); i++) {
		found = false;
		for (int j = 0; j < tojoin[i].size(); j++) {
			for (int k = 0; k < tojoin2.size(); k++) {
				for (int l = 0; l < tojoin2[k].size(); l++)
					if (tojoin[i][j] == tojoin2[k][l]) {
						tojoin2[k].insert(tojoin2[k].end(), tojoin[i].begin(), tojoin[i].end());
						//make each value unique
						sort(tojoin2[k].begin(), tojoin2[k].end());
						tojoin2[k].erase(unique(tojoin2[k].begin(), tojoin2[k].end()), tojoin2[k].end());
						found = true;
						break;
					}
				if (found) break;
			}
			if (found) break;
		}
		if (found == false)tojoin2.push_back(tojoin[i]);
	}

	joinedpos.clear();
	joinedpos.resize(tojoin2.size());
	for (int i = 0; i < tojoin2.size(); i++)
		for (int j = 0; j < tojoin2[i].size(); j++)joinedpos[i].insert(joinedpos[i].end(), initialcullpos[tojoin2[i][j]].begin(), initialcullpos[tojoin2[i][j]].end());


	initialcullpos = joinedpos;
	componentMeasurements(joinedpos, imagewidth, icmeasurementresults,imagef);//x centre, ycentre,eccentricity,length,x vec,yvec of major axis
}

*/
