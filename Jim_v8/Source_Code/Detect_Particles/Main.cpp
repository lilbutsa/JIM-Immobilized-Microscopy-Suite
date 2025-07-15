/*
 * Detect_Particles main.cpp
 *
 * Description:
 *   This program performs particle detection on an image using Laplacian of Gaussian (LoG) filtering,
 *   followed by binarization, and optional filtering based on shape, size, and position criteria.
 *
 * Usage:
 *   Detect_Particles <TIFF_Image> <Output_Base> [Optional Parameters]
 *
 * Optional Parameters:
 *   -BinarizeCutoff <float>           : Threshold multiplier for binarization (default 0.2)
 *   -minDistFromEdge <float>         : Minimum distance from all edges (overrides specific edges if larger)
 *   -left/-right/-top/-bottom <float>: Minimum distance from respective image edge
 *   -minEccentricity/-maxEccentricity<float>: Eccentricity filter
 *   -minLength/-maxLength <float>    : Length of major axis filter
 *   -minCount/-maxCount <float>      : Minimum/maximum number of pixels per region
 *   -maxDistFromLinear <float>       : Deviation from best-fit line
 *   -minSeparation <float>           : Minimum separation between region centers
 *   -GaussianStdDev <float>          : Standard deviation for LoG filter (default 5)
 *   -includeSmall                    : Include small regions in nearest neighbour calculations and for background ROI output
 *
 * Outputs (written to <Output_Base>.*):
 *   - _Regions.tif                   : Binary image showing detected ROIs
 *   - _Measurements.csv              : Raw measurements of all ROIs
 *   - _Positions.csv                 : Raw pixel positions of all ROIs
 *   - _Filtered_Regions.tif          : Binary image of filtered ROIs
 *   - _Filtered_Region_Numbers.tif   : ROI labels overlaid as indexed pixels
 *   - _Filtered_Measurements.csv     : Measurements of ROIs after filtering
 *   - _Filtered_Positions.csv        : Positions of ROIs after filtering
 *
 * Dependencies:
 *   - BLTiffIO: For TIFF input/output
 *   - BLCSVIO: For CSV input/output
 *   - BLImageTransform: For image filtering and analysis
 *   - BLFlagParser: For parsing command-line arguments
 *
 * @author James Walsh james.walsh@phys.unsw.edu.au
 * @date 2025-07-14
 */


#include <iostream>
#include <vector>
#include <algorithm>
#include "BLTiffIO.h"
#include "BLCSVIO.h"
#include "BLImageTransform.h"
#include "BLFlagParser.h"

class measurementsClass {
public:
	std::vector<float> asVector;
	float* xCentre, * yCentre, * eccentricity, * length, * xMajorAxis, * yMajorAxis, * count, * xMaxPos, * yMaxPos,
		* maxDistfromLinear, * xEnd1LinFit, * yEnd1LinFit, * xEnd2LinFit, * yEnd2LinFit, * xBoundingBoxMin, * xBoundingBoxMax, * yBoundingBoxMin, * yBoundingBoxMax, * nearestNeighbour;
};

void componentMeasurements(std::vector<std::vector<int> >& pos /*positions vector*/, int imagewidth, std::vector<measurementsClass>& measurementresults, std::vector<float>& imagef, const std::vector<uint8_t>& detected);
void numberimage(std::vector<std::vector<float> >& filteredcents, std::vector<uint8_t>& fn, int iw, int ih);
std::vector<std::vector<int> > binaryToPositions(const std::vector<uint8_t> binary, const int imageWidth, const int imageHeight);



int main(int argc, char *argv[])
{

	float binarizecutoff = 0.2;
	float minEccentricity = -0.1, maxEccentricity = 1.1, minLength = 0, maxLength = 10000000000, minCount = 0, maxCount = 1000000000, maxDistFromLinear = 10000000;
	bool filtering = false;

	float leftminDistFromEdge = -0.1, rightminDistFromEdge = -0.1, topminDistFromEdge = -0.1, bottomminDistFromEdge = -0.1,allminDistFromEdge = -0.1;

	float minSeparation = -1000;

	float gaussStdDev = -1;
	bool logStdDevChanged = false;
	bool includeSmall = false;

	//read in parameters

	if (argc < 3) { std::cout << "could not read file name\n"; return 1; }
	std::string inputfile = argv[1];
	std::string output = argv[2];

	std::vector<std::pair<std::string, float*> >params{ std::make_pair("BinarizeCutoff", &binarizecutoff),std::make_pair("minDistFromEdge", &allminDistFromEdge),
		std::make_pair("left", &leftminDistFromEdge),std::make_pair("right", &rightminDistFromEdge),std::make_pair("top", &topminDistFromEdge),std::make_pair("bottom", &bottomminDistFromEdge),
		std::make_pair("minEccentricity", &minEccentricity),std::make_pair("maxEccentricity", &maxEccentricity),std::make_pair("minLength", &minLength),std::make_pair("maxLength", &maxLength),
		std::make_pair("minCount", &minCount),std::make_pair("maxCount", &maxCount),std::make_pair("maxDistFromLinear", &maxDistFromLinear),std::make_pair("minSeparation", &minSeparation),
		std::make_pair("GaussianStdDev", &gaussStdDev) };

	if (BLFlagParser::parseValues(params, argc, argv)) return 1;

	if (allminDistFromEdge > leftminDistFromEdge)leftminDistFromEdge = allminDistFromEdge;
	if (allminDistFromEdge > rightminDistFromEdge)rightminDistFromEdge = allminDistFromEdge;
	if (allminDistFromEdge > topminDistFromEdge)topminDistFromEdge = allminDistFromEdge;
	if (allminDistFromEdge > bottomminDistFromEdge)bottomminDistFromEdge = allminDistFromEdge;

	if (gaussStdDev > 0) logStdDevChanged = true;
	else gaussStdDev = 5;

	std::vector<std::pair<std::string, bool*> > boolparams{ std::make_pair("includeSmall", &includeSmall) };
	if (BLFlagParser::parseValues(boolparams, argc, argv)) return 1;

	//read in image for detection

	BLTiffIO::TiffInput inputstack(inputfile);

	int imageDepth = inputstack.imageDepth;
	int imageWidth = inputstack.imageWidth;
	int imageHeight = inputstack.imageHeight;
	int imagePoints = imageWidth*imageHeight;
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
	double mean=0, stddev=0;
	meanAndStdDev(imlog, mean, stddev);
	std::vector<uint8_t> detected(imagePoints, 0);
	for (int i = 0; i < imagePoints; i++)if (imlog[i] > mean + binarizecutoff * stddev) detected[i] = 255; else detected[i] = 0;

	// Save the LOG filtered image if there is a specified gaussian std dev
	if (logStdDevChanged) {
		float minVal = *min_element(imlog.begin(), imlog.end());
		for (int i = 0; i < imagePoints; i++)imlog[i] = 1000 * (imlog[i] - minVal);
		BLTiffIO::TiffOutput(output + "_LOG_filtered.tif", imageWidth, imageHeight, 16).write1dImage(imlog);
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
	BLTiffIO::TiffOutput(output + "_Regions.tif", imageWidth, imageHeight, 8).write1dImage(detected);
	// Save the detected Positions
	std::vector<std::vector<int> > labelledposout = labelledpos;
	labelledposout.insert(labelledposout.begin(), { imageWidth,imageHeight,imagePoints });
	BLCSVIO::writeCSV(output + "_Positions.csv", labelledposout, "First Line is Image Size. Each Line is an ROI. Numbers Go Horizontal. To get {x;y}->{n%width;Floor(n/width)}\n");
	// Save initial measurements
	std::vector<std::vector<float>> measurementVector(measurementresults.size());
	for (int i = 0;i < measurementresults.size();i++)measurementVector[i] = measurementresults[i].asVector;
	BLCSVIO::writeCSV(output + "_Measurements.csv", measurementVector, "x Centroid, y Centroid,Eccentricity, Length ,x Vector of major axis,Y Vector of major axis, Count,X Max Pos, Y Max Pos, Max Dist From Linear Fit, End 1 x,End 1 Y, End 2 X,End 2 Y,X bounding Box Min, X Bounding Box Max,Y bounding Box Min, Y Bounding Box Max, Nearest Neighbour\n");



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
	BLTiffIO::TiffOutput(output + "_Filtered_Regions.tif", imageWidth, imageHeight, 8).write1dImage(filtereddetected);


	//make the numbers image
	std::vector<uint8_t> numberedimage(imagePoints, 0);
	numberimage(filteredmeasurements, numberedimage, imageWidth, imageHeight);
	BLTiffIO::TiffOutput(output + "_Filtered_Region_Numbers.tif", imageWidth, imageHeight, 8).write1dImage(numberedimage);


	//save filtered measurements
	BLCSVIO::writeCSV(output + "_Filtered_Measurements.csv", filteredmeasurements, "x Centroid, y Centroid,Eccentricity, Length ,x Vector of major axis,Y Vector of major axis, Count,X Max Pos, Y Max Pos, Max Dist From Linear Fit, End 1 x,End 1 Y, End 2 X,End 2 Y,X bounding Box Min, X Bounding Box Max,Y bounding Box Min, Y Bounding Box Max,Min Separation,Nearest Neighbour\n");
	labelledposout = filteredpos;
	labelledposout.insert(labelledposout.begin(), { imageWidth,imageHeight,imagePoints });
	BLCSVIO::writeCSV(output + "_Filtered_Positions.csv", labelledposout, "First Line is Image Size. Each Line is an ROI. Numbers Go Horizontal. To get {x;y}->{n%width;Floor(n/width)}\n");


	return 0;
}