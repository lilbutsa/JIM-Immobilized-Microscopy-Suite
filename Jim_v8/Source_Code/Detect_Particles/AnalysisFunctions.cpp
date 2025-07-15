/*
 * AnalysisFunctions.cpp
 *
 * Description:
 *   This file provides core analysis routines for extracting geometric and spatial measurements from
 *   ROIs detected in image data. 
 *
 *
 * Public Classes:
 *   - measurementsClass: Stores ROI measurements results.
 *   - nearestNeighbour: A 2D nearest-neighbour query class.
 *
 * Public Functions:
 *   - binaryToPositions(): Extracts vectorized ROIs from a flat binary mask using 8-connected labeling.
 *   - componentMeasurements(): Computes shape, structure, and neighbour proximity metrics for a set of ROIs.
 *
 *
 * @author James Walsh james.walsh@phys.unsw.edu.au
 * @date 2025-07-14
 */


#include <iostream>
#include <vector>
#include <algorithm>
#include <numeric>

class nearestNeighbour {
	
	std::vector<float>dists;
	bool constUsed;
public:
	std::vector<std::vector<float>>points;
	std::vector<size_t> idx;
	float minDistWithoutConstants;

	nearestNeighbour(const std::vector<std::vector<float>>& pointsin) :points(pointsin) {

		dists = std::vector<float>(pointsin.size());
		idx = std::vector<size_t>(pointsin.size());
		constUsed = false;
		minDistWithoutConstants = 0;
		
	}

	inline void query(const std::vector<float>& queryPoint) {
		constUsed = false;
		std::transform(points.begin(), points.end(), dists.begin(), [&](auto& value) 
			{ return (value[0]- queryPoint[0])* (value[0] - queryPoint[0])+ (value[1] - queryPoint[1])* (value[1] - queryPoint[1]); });
		iota(idx.begin(), idx.end(), 0);
		stable_sort(idx.begin(), idx.end(),[&](size_t i1, size_t i2) {return dists[i1] < dists[i2];});

		minDistWithoutConstants = sqrt(dists[idx[0]]);
	}

	inline void queryMinusConst(const std::vector<float>& queryPoint, const std::vector<float>& constant, float const2) {
		constUsed = true;
		std::transform(points.begin(), points.end(), constant.begin(), dists.begin(), [&](auto& value, auto& myconst)
			{ return sqrt((value[0] - queryPoint[0]) * (value[0] - queryPoint[0]) + (value[1] - queryPoint[1]) * (value[1] - queryPoint[1])) - myconst- const2; });
		iota(idx.begin(), idx.end(), 0);
		stable_sort(idx.begin(), idx.end(), [&](size_t i1, size_t i2) {return dists[i1] < dists[i2];});

		minDistWithoutConstants = dists[idx[1]]+ constant[idx[1]]+ const2;
	}


	inline float getDist(size_t index) {
		return constUsed? dists[idx[index]] :sqrt(dists[idx[index]]);
	}


};



std::vector<std::vector<int> > binaryToPositions(const std::vector<uint8_t> binary,const int imageWidth, const int imageHeight) {

	std::vector<std::vector<int> > positions;

	std::vector<uint16_t>posImage(binary.size(), 0);

	const std::vector<int> xedges = { -1,0,1,-1,1,-1,0,1 };
	const std::vector<int> yedges = { -1,-1,-1,0,0,1,1,1 };

	int count = 0;
	for (int i = 0;i < binary.size();i++)
		if (binary[i] > 0 && posImage[i]==0) {
			count++;
			std::vector<int> newROI = { i };

			posImage[i] = count;

			for (int j = 0;j < newROI.size();j++) {
				int xIn = newROI[j] % imageWidth;
				int yIn = newROI[j] / imageWidth;


				for (int k = 0;k < xedges.size();k++) {
					int xIn2 = xIn + xedges[k];
					int yIn2 = yIn + yedges[k];
					int posIn = xIn2 + yIn2 * imageWidth;

					if (xIn2 > -1 && xIn2 < imageWidth && yIn2 > -1 && yIn2 < imageHeight && binary[posIn] > 0 && posImage[posIn] == 0) {
						newROI.push_back(posIn);
						posImage[posIn] = count;
					}


				}


			}

			positions.push_back(newROI);

		}

	return positions;
}

class measurementsClass {
public:
	std::vector<float> asVector;
	float *xCentre, *yCentre, *eccentricity, *length, *xMajorAxis, *yMajorAxis, *count, *xMaxPos, *yMaxPos,
		*maxDistfromLinear, *xEnd1LinFit, *yEnd1LinFit, *xEnd2LinFit, *yEnd2LinFit, *xBoundingBoxMin, *xBoundingBoxMax, *yBoundingBoxMin, *yBoundingBoxMax, *nearestNeighbour;

	measurementsClass() {
		asVector = std::vector<float>(19, 0);
		xCentre = &(asVector[0]);
		yCentre = &(asVector[1]);
		eccentricity = &(asVector[2]);
		length = &(asVector[3]);
		xMajorAxis = &(asVector[4]);
		yMajorAxis = &(asVector[5]);
		count = &(asVector[6]);
		xMaxPos = &(asVector[7]);
		yMaxPos = &(asVector[8]);
		maxDistfromLinear = &(asVector[9]); 
		xEnd1LinFit = &(asVector[10]);
		yEnd1LinFit = &(asVector[11]);
		xEnd2LinFit = &(asVector[12]);
		yEnd2LinFit = &(asVector[13]);
		xBoundingBoxMin = &(asVector[14]);
		xBoundingBoxMax = &(asVector[15]);
		yBoundingBoxMin = &(asVector[16]);
		yBoundingBoxMax = &(asVector[17]);
		nearestNeighbour = &(asVector[18]);
	}

};


void componentMeasurements(std::vector<std::vector<int> >& pos /*positions vector*/, int imagewidth, std::vector<measurementsClass>& measurementresults, std::vector<float>& imagef, const std::vector<uint8_t>& detected) {
	measurementresults = std::vector < measurementsClass>(pos.size());
	std::vector<float> xpos, ypos;//x centre, ycentre,eccentricity,length,x vec,yvec of major axis,count, xmax pos, y max pos, maxdistfromlinear, x end 1, y end 1, x end 2, y end 2,X bounding Box Min, X Bounding Box Max,Y bounding Box Min, Y Bounding Box Max,Nearest Neighbour
	std::vector<float> vx2, vy2;
	float x2, y2, xy;
	float max, max2, min;
	int maxpos;

	//create knn for each for each ROI
	std::vector<nearestNeighbour> ROIKNNs;


	for (int i = 0; i < pos.size(); i++) {
		xpos.resize(pos[i].size());
		ypos.resize(pos[i].size());
		for (int j = 0; j < pos[i].size(); j++) {
			xpos[j] = pos[i][j] % imagewidth; ypos[j] = (int)(pos[i][j] / imagewidth);
		}
		//x and y centre of mass
		*(measurementresults[i].xCentre) = (float)std::accumulate(std::begin(xpos), std::end(xpos), 0.0) / xpos.size();
		*(measurementresults[i].yCentre) = (float)std::accumulate(std::begin(ypos), std::end(ypos), 0.0) / ypos.size();


		//subtract Centre of mass from positions
		std::transform(xpos.begin(), xpos.end(), xpos.begin(), [&](auto& value) { return value - *(measurementresults[i].xCentre); });
		std::transform(ypos.begin(), ypos.end(), ypos.begin(), [&](auto& value) { return value - *(measurementresults[i].yCentre); });


		//best fit ellipse
		x2 = std::inner_product(xpos.begin(), xpos.end(), xpos.begin(), 0.0) / xpos.size();
		y2 = std::inner_product(ypos.begin(), ypos.end(), ypos.begin(), 0.0) / ypos.size();
		xy = std::inner_product(xpos.begin(), xpos.end(), ypos.begin(), 0.0) / xpos.size();

		*(measurementresults[i].eccentricity) = ((x2 - y2) * (x2 - y2) + 4 * xy * xy) / ((x2 + y2) * (x2 + y2));//Eccentricity from https://docs.baslerweb.com/visualapplets/files/manuals/content/examples%20imagemoments.html

		float mainAxisAngle = 0.5 * atan2f(2*xy,(x2-y2));//theta = 1/2*np.arctan2(2*mu11/mu00, (mu20 - mu02)/mu00) from https://ojskrede.github.io/inf4300/notes/week_05/ 

		*(measurementresults[i].xMajorAxis) = cosf(mainAxisAngle);//x main axis
		*(measurementresults[i].yMajorAxis) = sinf(mainAxisAngle);//y main axis

		if (*(measurementresults[i].xMajorAxis) < 0) {
			*(measurementresults[i].xMajorAxis) *= -1.0; 
			*(measurementresults[i].yMajorAxis) *= -1.0;
		}

		//Find the projection of each point along the semi major axis. Max proj. - Min. Proj. gives length

		max = 0; 
		min = 0;
		for (int j = 0;j < xpos.size();j++) {
			float proj = xpos[j] * (*(measurementresults[i].xMajorAxis))+ ypos[j] * (*(measurementresults[i].yMajorAxis));
			if (proj < min)min = proj;
			if (proj > max)max = proj;
		}
		*(measurementresults[i].length) = max - min;
		// Ends are taken as the projections

		*(measurementresults[i].xEnd1LinFit) = *(measurementresults[i].xCentre) + *(measurementresults[i].xMajorAxis) * min;
		*(measurementresults[i].yEnd1LinFit) = *(measurementresults[i].yCentre) + *(measurementresults[i].yMajorAxis) * min;

		*(measurementresults[i].xEnd2LinFit) = *(measurementresults[i].xCentre) + *(measurementresults[i].xMajorAxis) * max;
		*(measurementresults[i].yEnd2LinFit) = *(measurementresults[i].yCentre) + *(measurementresults[i].yMajorAxis) * max;


		*(measurementresults[i].count) = xpos.size();


		//Pixel Position of the max intensity
		max = 0;
		maxpos = 0;
		for (int j = 0; j < pos[i].size(); j++) {
			if (imagef[pos[i][j]] > max) {
				max = imagef[pos[i][j]];
				maxpos = pos[i][j];
			}
		}

		*(measurementresults[i].xMaxPos) = maxpos % imagewidth;
		*(measurementresults[i].yMaxPos) = (int)(maxpos / imagewidth);

		//max distance from linear. note xpos and y pos have subtracted their COM
		//dist = abs(x*yvec-y*xvec)
		max = 0;
		for (int j = 0; j < xpos.size(); j++) {
			float dist = abs(xpos[j]* *(measurementresults[i].yMajorAxis) -ypos[j]* *(measurementresults[i].xMajorAxis));
			if (dist > max)max = dist;
		}
		*(measurementresults[i].maxDistfromLinear) = max;

		//Bounding box
		auto minMax = std::minmax_element(xpos.begin(), xpos.end());
		*(measurementresults[i].xBoundingBoxMin) = *minMax.first + *(measurementresults[i].xCentre);
		*(measurementresults[i].xBoundingBoxMax) = *minMax.second + *(measurementresults[i].xCentre);

		minMax = std::minmax_element(ypos.begin(), ypos.end());
		*(measurementresults[i].yBoundingBoxMin) = *minMax.first + *(measurementresults[i].yCentre);
		*(measurementresults[i].yBoundingBoxMax) = *minMax.second + *(measurementresults[i].yCentre);

		//load edge positions into KNN for next section
		std::vector<std::vector<float>> edgePos2D;
		for (int j = 0; j < xpos.size(); j++) {
			if (xpos[j] == 0 || detected[xpos[j] - 1 + imagewidth * ypos[j]] == 0)edgePos2D.push_back({ xpos[j]+ *(measurementresults[i].xCentre),ypos[j] + *(measurementresults[i].yCentre) });
			else if (xpos[j] == imagewidth-1 || detected[xpos[j] + 1 + imagewidth * ypos[j]] == 0)edgePos2D.push_back({ xpos[j] + *(measurementresults[i].xCentre),ypos[j] + *(measurementresults[i].yCentre) });
			else if (ypos[j] == 0 || detected[xpos[j] + imagewidth * (ypos[j]-1)] == 0)edgePos2D.push_back({ xpos[j] + *(measurementresults[i].xCentre),ypos[j] + *(measurementresults[i].yCentre) });
			else if ((ypos[j]+1) * imagewidth == detected.size() || detected[xpos[j] + imagewidth * (ypos[j]+1)] == 0)edgePos2D.push_back({ xpos[j] + *(measurementresults[i].xCentre),ypos[j] + *(measurementresults[i].yCentre) });
		}
		ROIKNNs.push_back(nearestNeighbour(edgePos2D));     

	}

	//Once all ROIs have been measured, calculate nearest neighbour using best fit ellipse

	//create KNN network for COMs
	std::vector<std::vector<float>> COMPositions(measurementresults.size(), std::vector<float>(2, 0));
	std::vector<float> radiuses(measurementresults.size());
	for (int i = 0;i < measurementresults.size();i++) {
		COMPositions[i][0] = *(measurementresults[i].xCentre);
		COMPositions[i][1] = *(measurementresults[i].yCentre);
		radiuses[i] = *(measurementresults[i].length);
	}
	nearestNeighbour myKNN(COMPositions);

	for (int i = 0;i < measurementresults.size();i++) {
		
		myKNN.queryMinusConst(COMPositions[i], radiuses, radiuses[i]);
		float minDist = myKNN.minDistWithoutConstants;
		int nearestPixel = 0;
		int count = 1;
		while (myKNN.getDist(count) < minDist) {
			for (int j = 0;j < ROIKNNs[i].points.size();j++) {
				ROIKNNs[myKNN.idx[count]].query(ROIKNNs[i].points[j]);
				if (ROIKNNs[myKNN.idx[count]].getDist(0) < minDist)minDist = ROIKNNs[myKNN.idx[count]].getDist(0);
			}

			count++;
		}
		*(measurementresults[i].nearestNeighbour) = minDist;


	}

}