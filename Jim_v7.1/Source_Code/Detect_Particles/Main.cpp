#include <string>
#include <iostream>
#include <vector>
#include <algorithm>
#include "BLTiffIO.h"
#include "BLCSVIO.h"
#include "ipp.h"
#include <float.h>

void convertlabelledtopositions(std::vector<int>& labelled, int& numfound, std::vector<std::vector<int> >& labelledpos);
void componentMeasurements(std::vector<std::vector<int> >& pos2 /*positions vector*/, int imagewidth, std::vector<std::vector<float> > & measurementresults, std::vector<float> & imagef);
void numberimage(std::vector<std::vector<float> >& filteredcents, std::vector<uint8_t>& fn, int iw, int ih);

void nearestNeighbour(std::vector<std::vector<float> >& centroidresults, std::vector<std::vector<int> >& pos2 /*positions vector*/, int imagewidth, std::vector<float>& nearestNeighbourVec);


#define SQUARE(x) ((x)*(x))

using namespace std;


int main(int argc, char *argv[])
{


	double binarizecutoff = 0.2;
	double minDistFromEdge = -0.1, minEccentricity = -0.1, maxEccentricity = 1.1, minLength = 0, maxLength = 10000000000, minCount = 0, maxCount = 1000000000, maxDistFromLinear = 10000000;
	bool filtering = false;

	double leftminDistFromEdge = -0.1, rightminDistFromEdge = -0.1, topminDistFromEdge = -0.1, bottomminDistFromEdge = -0.1;

	double minSeparation = -1000;

	if (argc < 3) { std::cout << "could not read file name" << endl; return 1; }
	std::string inputfile = argv[1];
	std::string output = argv[2];

	for (int i = 1; i < argc; i++) {
		if (std::string(argv[i]) == "-BinarizeCutoff") {
			if (i + 1 < argc) {
				binarizecutoff = stod(argv[i + 1]);
				cout << "Binarize cutoff off set to " << binarizecutoff << endl;
			}
			else { std::cout << "error inputting cutoff" << std::endl; return 1; }
		}
		if (std::string(argv[i]) == "-minDistFromEdge") {
			if (i + 1 < argc) {
				minDistFromEdge = stod(argv[i + 1]);
				leftminDistFromEdge = minDistFromEdge, rightminDistFromEdge = minDistFromEdge, topminDistFromEdge = minDistFromEdge, bottomminDistFromEdge = minDistFromEdge;
				cout << "Minimum Distance From Edge of Image set to " << minDistFromEdge << endl;
				filtering = true;
			}
			else { std::cout << "error inputting Minimum Distance From Edge" << std::endl; return 1; }
		}
		if (std::string(argv[i]) == "-left") {
			if (i + 1 < argc) {
				leftminDistFromEdge = stod(argv[i + 1]);
				cout << "Left Minimum Distance From Edge of Image set to " << leftminDistFromEdge << endl;
				filtering = true;
			}
			else { std::cout << "error inputting Minimum Distance From Edge" << std::endl; return 1; }
		}
		if (std::string(argv[i]) == "-right") {
			if (i + 1 < argc) {
				rightminDistFromEdge = stod(argv[i + 1]);
				cout << "Right Minimum Distance From Edge of Image set to " << rightminDistFromEdge << endl;
				filtering = true;
			}
			else { std::cout << "error inputting Minimum Distance From Edge" << std::endl; return 1; }
		}
		if (std::string(argv[i]) == "-top") {
			if (i + 1 < argc) {
				topminDistFromEdge = stod(argv[i + 1]);
				cout << "Top Minimum Distance From Edge of Image set to " << topminDistFromEdge << endl;
				filtering = true;
			}
			else { std::cout << "error inputting Minimum Distance From Edge" << std::endl; return 1; }
		}
		if (std::string(argv[i]) == "-bottom") {
			if (i + 1 < argc) {
				bottomminDistFromEdge = stod(argv[i + 1]);
				cout << "Bottom Minimum Distance From Edge of Image set to " << bottomminDistFromEdge << endl;
				filtering = true;
			}
			else { std::cout << "error inputting Minimum Distance From Edge" << std::endl; return 1; }
		}
		if (std::string(argv[i]) == "-minEccentricity") {
			if (i + 1 < argc) {
				minEccentricity = stod(argv[i + 1]);
				cout << "Minimum Eccentricity set to " << minEccentricity << endl;
				filtering = true;
			}
			else { std::cout << "error inputting Minimum Eccentricity From Edge" << std::endl; return 1; }
		}
		if (std::string(argv[i]) == "-maxEccentricity") {
			if (i + 1 < argc) {
				maxEccentricity = stod(argv[i + 1]);
				cout << "Maximum Eccentricity set to " << maxEccentricity << endl;
				filtering = true;
			}
			else { std::cout << "error inputting maximum Eccentricity From Edge" << std::endl; return 1; }
		}
		if (std::string(argv[i]) == "-minLength") {
			if (i + 1 < argc) {
				minLength = stod(argv[i + 1]);
				cout << "Minimum Length set to " << minLength << endl;
				filtering = true;
			}
			else { std::cout << "error inputting minimum length" << std::endl; return 1; }
		}
		if (std::string(argv[i]) == "-maxLength") {
			if (i + 1 < argc) {
				maxLength = stod(argv[i + 1]);
				cout << "Maximum Length set to " << maxLength << endl;
				filtering = true;
			}
			else { std::cout << "error inputting maximum length" << std::endl; return 1; }
		}
		if (std::string(argv[i]) == "-minCount") {
			if (i + 1 < argc) {
				minCount = stod(argv[i + 1]);
				cout << "Minimum Count set to " << minCount << endl;
				filtering = true;
			}
			else { std::cout << "error inputting minimum Count" << std::endl; return 1; }
		}
		if (std::string(argv[i]) == "-maxCount") {
			if (i + 1 < argc) {
				maxCount = stod(argv[i + 1]);
				cout << "Maximum Count set to " << maxCount << endl;
				filtering = true;
			}
			else { std::cout << "error inputting maximum Count" << std::endl; return 1; }
		}
		if (std::string(argv[i]) == "-maxDistFromLinear") {
			if (i + 1 < argc) {
				maxDistFromLinear = stod(argv[i + 1]);
				cout << "Maximum Distance From Linear set to " << maxDistFromLinear << endl;
				filtering = true;
			}
			else { std::cout << "error inputting Maximum Distance From Linear" << std::endl; return 1; }
		}
		if (std::string(argv[i]) == "-minSeparation") {
			if (i + 1 < argc) {
				minSeparation = stod(argv[i + 1]);
				cout << "Minimum Separation Distance between regions set to " << minSeparation << endl;
				filtering = true;
			}
			else { std::cout << "error inputting Minimum Separation Distance" << std::endl; return 1; }
		}
	}


	BLTiffIO::TiffInput inputstack(inputfile);

	int imageDepth = inputstack.imageDepth;
	int imageWidth = inputstack.imageWidth;
	int imageHeight = inputstack.imageHeight;
	int imagePoints = imageWidth*imageHeight;
	int totnumofframes = inputstack.numOfFrames;




	IppiSize roiSize = { imageWidth, imageHeight };
	Ipp32u kernelSize = 5;
	int iTmpBufSize = 0, iSpecSize = 0;
	ippiFilterGaussianGetBufferSize(roiSize, kernelSize, ipp32f, 1, &iSpecSize, &iTmpBufSize);
	IppFilterGaussianSpec* pSpec = (IppFilterGaussianSpec *)ippsMalloc_8u(iSpecSize);
	Ipp8u* pBuffer = ippsMalloc_8u(iTmpBufSize);
	ippiFilterGaussianInit(roiSize, kernelSize, 2.5, ippBorderRepl, ipp32f, 1, pSpec, pBuffer);
	vector<float> gaussblurred(imagePoints, 0), imlog(imagePoints, 0), imagef(imagePoints, 0);

	ippiFilterLaplaceBorderGetBufferSize(roiSize, ippMskSize5x5, ipp32f, ipp32f, 1, &iTmpBufSize);
	Ipp8u* pBuffer1 = ippsMalloc_8u(iTmpBufSize);



	double mean, stddev;
	vector<uint8_t> detected(imagePoints, 0);


	IppiMorphState* pSpecd = NULL;
	Ipp8u* pBufferd = NULL;
	Ipp8u pMaskd[3 * 3] = { 1, 1, 1,1, 0, 1,1, 1, 1 };
	IppiSize maskSized = { 3, 3 };
	int specSized = 0, bufferSized = 0;
	ippiMorphologyBorderGetSize_16u_C1R(roiSize, maskSized, &specSized, &bufferSized);
	pSpecd = (IppiMorphState*)ippsMalloc_8u(specSized);
	pBufferd = (Ipp8u*)ippsMalloc_8u(bufferSized);
	ippiMorphologyBorderInit_16u_C1R(roiSize, pMaskd, maskSized, pSpecd, pBufferd);



	int bufferSize3;
	ippiLabelMarkersGetBufferSize_8u32s_C1R(roiSize, &bufferSize3);
	Ipp8u* pBuffer3 = ippsMalloc_8u(bufferSize3);

	int numfound;
	std::vector<int> labelled(imagePoints, 0);
	std::vector<std::vector<int> > labelledpos, filteredpos;
	std::vector<std::vector<float> > centroidresults, filteredcents;

	inputstack.read1dImage(0,imagef);

	ippiFilterGaussianBorder_32f_C1R(&imagef[0], imageWidth * sizeof(Ipp32f), &gaussblurred[0], imageWidth * sizeof(Ipp32f), roiSize, ippBorderRepl, pSpec, pBuffer);
	ippiFilterLaplaceBorder_32f_C1R(&gaussblurred[0], imageWidth * sizeof(Ipp32f), &imlog[0], imageWidth * sizeof(Ipp32f), roiSize, ippMskSize5x5, ippBorderRepl, 0, pBuffer1);
	ippiMean_StdDev_32f_C1R(&imlog[0], imageWidth * sizeof(Ipp32f), roiSize, &mean, &stddev);

	for (int i = 0; i < imagePoints; i++)if (imlog[i] > mean + binarizecutoff * stddev) detected[i] = 255; else detected[i] = 0;


	ippiLabelMarkers_8u32s_C1R(&detected[0], imageWidth * sizeof(Ipp8u), &labelled[0], imageWidth * sizeof(int), roiSize, 1, imagePoints, ippiNormL1, &numfound, pBuffer3);


	convertlabelledtopositions(labelled, numfound, labelledpos);

	int initialsize = labelledpos.size()-1;
	for (int i = initialsize; i > -1; i--) {
		if (labelledpos[i].size() == 0) {
			labelledpos.erase(labelledpos.begin()+i);
		}
	}

	componentMeasurements(labelledpos, imageWidth, centroidresults, imagef);

	vector<uint8_t> detectedimage(imagePoints, 0);
	for (int i = 0; i < labelledpos.size(); i++)for (int j = 0; j<labelledpos[i].size(); j++) detectedimage[labelledpos[i][j]] = 255;


	BLTiffIO::TiffOutput(output + "_Regions.tif", imageWidth, imageHeight,8).write1dImage(detectedimage);
	BLCSVIO::writeCSV(output + "_Measurements.csv", centroidresults, "x Centroid, y Centroid,Eccentricity, Length ,x Vector of major axis,Y Vector of major axis, Count,X Max Pos, Y Max Pos, Max Dist From Linear Fit, End 1 x,End 1 Y, End 2 X,End 2 Y,X bounding Box Min, X Bounding Box Max,Y bounding Box Min, Y Bounding Box Max\n");
	std::vector<std::vector<int> > labelledposout = labelledpos;
	labelledposout.insert(labelledposout.begin(), { imageWidth,imageHeight,imagePoints });
	BLCSVIO::writeCSV(output + "_Positions.csv", labelledposout, "First Line is Image Size. Each Line is an ROI. Numbers Go Horizontal. To get {x;y}->{n%width;Floor(n/width)}\n");
	//BLCSVIO::writeCSV(output + "_Labelled_Positions.csv", labelledpos, "Each Line is a ROI\n");

	if (filtering == false)return 0;

	vector<float> nearestNeighbourVec(centroidresults.size(),FLT_MAX);
	if(minSeparation>0.5)nearestNeighbour(centroidresults, labelledpos,imageWidth, nearestNeighbourVec);

	for (int i = 0; i < centroidresults.size(); i++) {
		if (((double)nearestNeighbourVec[i])>minSeparation && centroidresults[i][14] >= leftminDistFromEdge && centroidresults[i][15] <= imageWidth - 1 - rightminDistFromEdge && centroidresults[i][16] >= topminDistFromEdge && centroidresults[i][17] <= imageHeight - 1 - bottomminDistFromEdge
			&& centroidresults[i][2] >= minEccentricity && centroidresults[i][2] <= maxEccentricity && centroidresults[i][3] >= minLength && centroidresults[i][3] <= maxLength
			&& centroidresults[i][6] >= minCount && centroidresults[i][6] <= maxCount && centroidresults[i][9] <= maxDistFromLinear) {
			filteredpos.push_back(labelledpos[i]);
			centroidresults[i].push_back(nearestNeighbourVec[i]);
			filteredcents.push_back(centroidresults[i]);
		}
	}

	vector<uint8_t> filtereddetected(imagePoints, 0);
	for (int i = 0; i < filteredpos.size(); i++)for (int j = 0; j<filteredpos[i].size(); j++) filtereddetected[filteredpos[i][j]] = 255;

	vector<uint8_t> numberedimage(imagePoints, 0);
	numberimage(filteredcents, numberedimage, imageWidth,imageHeight);
	BLTiffIO::TiffOutput(output + "_Filtered_Region_Numbers.tif", imageWidth, imageHeight, 8).write1dImage(numberedimage);

	BLTiffIO::TiffOutput(output + "_Filtered_Regions.tif", imageWidth, imageHeight,8).write1dImage(filtereddetected);

	BLCSVIO::writeCSV(output + "_Filtered_Measurements.csv", filteredcents, "x Centroid, y Centroid,Eccentricity, Length ,x Vector of major axis,Y Vector of major axis, Count,X Max Pos, Y Max Pos, Max Dist From Linear Fit, End 1 x,End 1 Y, End 2 X,End 2 Y,X bounding Box Min, X Bounding Box Max,Y bounding Box Min, Y Bounding Box Max,Min Separation\n");
	//BLCSVIO::writeCSV(output + "_Filtered_Labelled_Positions.csv", filteredpos, "Each Line is an ROI. Numbers Go Horizontal. To get {x;y}->{n%width;Floor(n/width)}\n");
	labelledposout = filteredpos;
	labelledposout.insert(labelledposout.begin(), { imageWidth,imageHeight,imagePoints });
	BLCSVIO::writeCSV(output + "_Filtered_Positions.csv", labelledposout, "First Line is Image Size. Each Line is an ROI. Numbers Go Horizontal. To get {x;y}->{n%width;Floor(n/width)}\n");

	//system("PAUSE");
	return 0;
}