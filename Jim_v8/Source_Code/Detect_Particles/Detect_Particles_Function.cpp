#include <iostream>
#include <vector>
#include <algorithm>
#include "BLTiffIO.h"
#include "BLCSVIO.h"
#include "BLImageTransform.h"

class measurementsClass {
public:
	std::vector<float> asVector;
	float* xCentre, * yCentre, * eccentricity, * length, * xMajorAxis, * yMajorAxis, * count, * xMaxPos, * yMaxPos,
		* maxDistfromLinear, * xEnd1LinFit, * yEnd1LinFit, * xEnd2LinFit, * yEnd2LinFit, * xBoundingBoxMin, * xBoundingBoxMax, * yBoundingBoxMin, * yBoundingBoxMax, * nearestNeighbour;
};

void componentMeasurements(std::vector<std::vector<int> >& pos /*positions vector*/, int imagewidth, std::vector<measurementsClass>& measurementresults, std::vector<float>& imagef, const std::vector<uint8_t>& detected);
void numberimage(std::vector<std::vector<float> >& filteredcents, std::vector<uint8_t>& fn, int iw, int ih);
std::vector<std::vector<int> > binaryToPositions(const std::vector<uint8_t> binary, const int imageWidth, const int imageHeight);


int Detect_Particles(std::string fileBase, std::string inputfile, double gaussStdDev, double binarizecutoff, double minSeparation, double leftminDistFromEdge, double rightminDistFromEdge, double topminDistFromEdge, double bottomminDistFromEdge, 
	double minEccentricity, double maxEccentricity, double minLength, double maxLength, double minCount, double maxCount, double maxDistFromLinear, bool includeSmall) {
	//read in image for detection

	BLTiffIO::TiffInput inputstack(inputfile);

	int imageDepth = inputstack.imageDepth;
	int imageWidth = inputstack.imageWidth;
	int imageHeight = inputstack.imageHeight;
	int imagePoints = imageWidth * imageHeight;
	int totnumofframes = inputstack.numOfFrames;

	//pure std c++ version

	//read in image
	std::vector<float> imagef(imagePoints, 0);
	inputstack.read1dImage(0, imagef);

	//apply laplace of gaussian filter
	alignImages_32f myFFT(imageWidth, imageHeight);
	myFFT.laplaciandOfGaussian(imagef, gaussStdDev);
	std::vector<float> imlog = myFFT.realDataOut;

	//Binarize above threshold
	double mean = 0, stddev = 0;
	meanAndStdDev(imlog, mean, stddev);
	std::vector<uint8_t> detected(imagePoints, 0);
	for (int i = 0; i < imagePoints; i++)if (imlog[i] > mean + binarizecutoff * stddev) detected[i] = 255; else detected[i] = 0;

	// Save the LOG filtered image if there is a specified gaussian std dev
	if (std::abs(gaussStdDev-5)<0.01) {
		float minVal = *min_element(imlog.begin(), imlog.end());
		for (int i = 0; i < imagePoints; i++)imlog[i] = 1000 * (imlog[i] - minVal);
		BLTiffIO::TiffOutput(fileBase + "_LOG_filtered.tif", imageWidth, imageHeight, 16).write1dImage(imlog);
	}

	//Seperate individual ROIs in the Binary image
	std::vector<std::vector<int> > labelledpos = binaryToPositions(detected, imageWidth, imageHeight);

	//Exclude small ROI from further analysis
	if (!includeSmall) {
		int numRemoved = 0;
		for (int i = 0;i < labelledpos.size();i++) {
			if (labelledpos[i].size() < minCount)numRemoved++;
			else labelledpos[i - numRemoved] = labelledpos[i];
		}
		labelledpos.resize(labelledpos.size() - numRemoved);
	}

	//Measure ROI characteristics
	std::vector<measurementsClass > measurementresults;
	componentMeasurements(labelledpos, imageWidth, measurementresults, imagef, detected);

	//write out unfiltered results

	// Save the detected Binary image
	BLTiffIO::TiffOutput(fileBase + "_Regions.tif", imageWidth, imageHeight, 8).write1dImage(detected);
	// Save the detected Positions
	std::vector<std::vector<int> > labelledposout = labelledpos;
	labelledposout.insert(labelledposout.begin(), { imageWidth,imageHeight,imagePoints });
	BLCSVIO::writeCSV(fileBase + "_Positions.csv", labelledposout, "First Line is Image Size. Each Line is an ROI. Numbers Go Horizontal. To get {x;y}->{n%width;Floor(n/width)}\n");
	// Save initial measurements
	std::vector<std::vector<float>> measurementVector(measurementresults.size());
	for (int i = 0;i < measurementresults.size();i++)measurementVector[i] = measurementresults[i].asVector;
	BLCSVIO::writeCSV(fileBase + "_Measurements.csv", measurementVector, "x Centroid, y Centroid,Eccentricity, Length ,x Vector of major axis,Y Vector of major axis, Count,X Max Pos, Y Max Pos, Max Dist From Linear Fit, End 1 x,End 1 Y, End 2 X,End 2 Y,X bounding Box Min, X Bounding Box Max,Y bounding Box Min, Y Bounding Box Max, Nearest Neighbour\n");



	//Filter ROIs
	std::vector<std::vector<int> > filteredpos;
	std::vector<std::vector<float> > filteredmeasurements;

	for (int i = 0; i < measurementresults.size(); i++) {
		bool keepROI = *measurementresults[i].nearestNeighbour >= minSeparation &&
			*measurementresults[i].xBoundingBoxMin >= leftminDistFromEdge && *measurementresults[i].xBoundingBoxMax <= imageWidth - 1 - rightminDistFromEdge && *measurementresults[i].yBoundingBoxMin >= topminDistFromEdge && *measurementresults[i].yBoundingBoxMax <= imageHeight - 1 - bottomminDistFromEdge &&
			*measurementresults[i].eccentricity >= minEccentricity && *measurementresults[i].eccentricity <= maxEccentricity &&
			*measurementresults[i].length >= minLength && *measurementresults[i].length <= maxLength &&
			*measurementresults[i].count >= minCount && *measurementresults[i].count <= maxCount &&
			*measurementresults[i].maxDistfromLinear <= maxDistFromLinear;

		if (keepROI) {
			filteredpos.push_back(labelledpos[i]);
			filteredmeasurements.push_back(measurementresults[i].asVector);
		}
	}


	//make the filtered detected image
	std::vector<uint8_t> filtereddetected(imagePoints, 0);
	for (int i = 0; i < filteredpos.size(); i++)for (int j = 0; j < filteredpos[i].size(); j++) filtereddetected[filteredpos[i][j]] = 255;
	BLTiffIO::TiffOutput(fileBase + "_Filtered_Regions.tif", imageWidth, imageHeight, 8).write1dImage(filtereddetected);


	//make the numbers image
	std::vector<uint8_t> numberedimage(imagePoints, 0);
	numberimage(filteredmeasurements, numberedimage, imageWidth, imageHeight);
	BLTiffIO::TiffOutput(fileBase + "_Filtered_Region_Numbers.tif", imageWidth, imageHeight, 8).write1dImage(numberedimage);


	//save filtered measurements
	BLCSVIO::writeCSV(fileBase + "_Filtered_Measurements.csv", filteredmeasurements, "x Centroid, y Centroid,Eccentricity, Length ,x Vector of major axis,Y Vector of major axis, Count,X Max Pos, Y Max Pos, Max Dist From Linear Fit, End 1 x,End 1 Y, End 2 X,End 2 Y,X bounding Box Min, X Bounding Box Max,Y bounding Box Min, Y Bounding Box Max,Min Separation,Nearest Neighbour\n");
	labelledposout = filteredpos;
	labelledposout.insert(labelledposout.begin(), { imageWidth,imageHeight,imagePoints });
	BLCSVIO::writeCSV(fileBase + "_Filtered_Positions.csv", labelledposout, "First Line is Image Size. Each Line is an ROI. Numbers Go Horizontal. To get {x;y}->{n%width;Floor(n/width)}\n");

	return 0;
}
