#include <string>
#include <iostream>
#include <vector>
#include <algorithm>
#include "BLTiffIO.h"
#include "BLImageTransform.h"
#include "BLCSVIO.h"

using namespace std;

//Input should be align file, drift file, outfile, all image files, -Start chan1 chan2...,-End chan1, chan2
int main(int argc, char *argv[])
{
	int numInputFiles = 0;

	bool maxproject = false;
	bool normalize = true;

	for (int i = 4; i < argc && std::string(argv[i]) != "-Start"&& std::string(argv[i]) != "-End"&& std::string(argv[i]) != "-MaxProjection" && std::string(argv[i]) != "-Weights"; i++) numInputFiles++;


	if (argc < 3) { std::cout << "could not read file name" << endl; return 1; }
	std::string alignfile = argv[1];
	std::string driftfile = argv[2];
	std::string outputfile = argv[3];

	vector<string> inputfiles(numInputFiles);
	for (int i = 0; i < numInputFiles; i++)inputfiles[i] = argv[i + 4];

	vector<BLTiffIO::TiffInput*> vcinput(numInputFiles);
	for (int i = 0; i < numInputFiles; i++)vcinput[i] = new BLTiffIO::TiffInput(inputfiles[i]);

	int imageDepth = vcinput[0]->imageDepth;
	int imageWidth = vcinput[0]->imageWidth;
	int imageHeight = vcinput[0]->imageHeight;
	int imagePoints = imageWidth * imageHeight;
	int totnumofframes = vcinput[0]->numOfFrames;


	vector<float> image1(imagePoints);



	vector<int> start(numInputFiles, 0);
	vector<int> end(numInputFiles, totnumofframes);

	vector<float> weights(numInputFiles, 1);

	std::cout << numInputFiles << " channels detected\n";
	std::string delimiter = " ";

	bool bPercentStartEnd = false;
	for (int i = 1; i < argc; i++)if (std::string(argv[i]) == "-Percent") bPercentStartEnd = true;

	for (int i = 1; i < argc; i++) {
		if (std::string(argv[i]) == "-Start") {
			int chanCount = 0;
			int argCount = 0;
			while (chanCount < numInputFiles) {
				if (i + argCount + 1 < argc) {
					size_t pos = 0;
					std::string inputStr = argv[i + argCount + 1];
					
					while ((pos = inputStr.find(delimiter)) != std::string::npos) {
						if(bPercentStartEnd) start[chanCount] = round(totnumofframes*stod(inputStr.substr(0, pos))/100.0);
						else start[chanCount] = stoi(inputStr.substr(0, pos)) - 1;

						inputStr.erase(0, pos + delimiter.length());
						chanCount++;
					}
					if (bPercentStartEnd) start[chanCount] = round(totnumofframes * stod(inputStr) / 100.0);
					else start[chanCount] = stoi(inputStr) - 1;
					chanCount++;
				}
				else { std::cout << "error inputting starts" << std::endl; return 1; }
				argCount++;
			};

			for (int j = 0; j < numInputFiles; j++) {
				if (start[j] < -1)start[j] = totnumofframes + start[j] + 1;
				start[j] = max(start[j], 0);
				cout << "Calculating mean of channel " << j + 1 << " starting from frame " << start[j] + 1 << endl;
			}
		}
		if (std::string(argv[i]) == "-End") {

			int chanCount = 0;
			int argCount = 0;
			while (chanCount < numInputFiles) {
				if (i + argCount + 1 < argc) {
					size_t pos = 0;
					std::string inputStr = argv[i + argCount + 1];
					while ((pos = inputStr.find(delimiter)) != std::string::npos) {
						if (bPercentStartEnd) end[chanCount] = round(totnumofframes * stod(inputStr.substr(0, pos)) / 100.0);
						else end[chanCount] = stoi(inputStr.substr(0, pos));
						inputStr.erase(0, pos + delimiter.length());
						chanCount++;
					}
					if (bPercentStartEnd) end[chanCount] = round(totnumofframes * stod(inputStr.substr(0, pos)) / 100.0);
					else end[chanCount] = stoi(inputStr);
					chanCount++;
				}
				else { std::cout << "error inputting starts" << std::endl; return 1; }
				argCount++;
			};


			for (int j = 0; j < numInputFiles; j++) {
					if (end[j] < 0)end[j] = totnumofframes + end[j]+1;
					end[j] = min(end[j], totnumofframes);
					cout << "Calculating mean of channel " << j + 1 << " ending at frame " << end[j] << endl;
			}
		}
		if (std::string(argv[i]) == "-Weights") {
			int chanCount = 0;
			int argCount = 0;
			while (chanCount < numInputFiles) {
				if (i + argCount + 1 < argc) {
					size_t pos = 0;
					std::string inputStr = argv[i + argCount + 1];
					while ((pos = inputStr.find(delimiter)) != std::string::npos) {
						weights[chanCount] = stoi(inputStr.substr(0, pos));
						inputStr.erase(0, pos + delimiter.length());
						chanCount++;
					}
					weights[chanCount] = stoi(inputStr);
					chanCount++;
				}
				else { std::cout << "error inputting starts" << std::endl; return 1; }
				argCount++;
			};

			cout << "Channel weights :";
			for (int k = 0; k < numInputFiles; k++) cout << " " << weights[k];
			cout << "\n";
		}
		if (std::string(argv[i]) == "-MaxProjection") {
			maxproject = true;
			cout << "Using Max Projection"<< endl;
		}
		if (std::string(argv[i]) == "-NoNorm") {
			normalize = false;
			cout << "Not Normalizing Image" << endl;
		}
	}
	//read in drifts
	vector< vector<double> > drifts(3000, vector<double>(2, 0.0));
	std::vector<std::string> headerLine;
	BLCSVIO::readCSV(driftfile, drifts,headerLine);
	//read in channel alignment
	vector< vector<double> > channelalignment(11, vector<double>(2, 0.0));
	if (numInputFiles>1)BLCSVIO::readCSV(alignfile, channelalignment,headerLine);

	vector<float> alignedimage(imagePoints, 0.0);
	vector< vector<float> > meanimage(numInputFiles, vector<float>(imagePoints, 0.0));
	imageTransform_32f transformclass(imageWidth, imageHeight);


	vector<float> rotimage(imagePoints), scaleimage(imagePoints);
	vector<float> translated(imagePoints);

	vector<float>Combinedmeanimage(imagePoints, 0.0);

	float transxoffset, transyoffset;
	int count;
	float divisor;
	for (int channelcount = 0; channelcount < numInputFiles; channelcount++) {
		count = 0;
		if (channelcount == 0) {
			for (int imcount = start[channelcount]; imcount < end[channelcount]; imcount++) {
				vcinput[channelcount]->read1dImage(imcount,image1);
				transformclass.translate(image1, alignedimage, -drifts[imcount][0], -drifts[imcount][1]);
				if (maxproject) std::transform(alignedimage.begin(), alignedimage.end(), meanimage[channelcount].begin(), meanimage[channelcount].begin(),[](float a, float b) { return std::max(a, b); });
				else std::transform(alignedimage.begin(), alignedimage.end(), meanimage[channelcount].begin(), meanimage[channelcount].begin(), std::plus<float>());
				count++;
			}

		}
		else {
			for (int imcount = start[channelcount]; imcount < end[channelcount]; imcount++) {
				transxoffset = (-drifts[imcount][0])*channelalignment[channelcount - 1][5] + (-drifts[imcount][1])*channelalignment[channelcount - 1][6];
				transyoffset = (-drifts[imcount][0])*channelalignment[channelcount - 1][7] + (-drifts[imcount][1])*channelalignment[channelcount - 1][8];
				vcinput[channelcount]->read1dImage(imcount, image1);
				transformclass.translate(image1, alignedimage, transxoffset, transyoffset);
				if (maxproject) std::transform(alignedimage.begin(), alignedimage.end(), meanimage[channelcount].begin(), meanimage[channelcount].begin(), [](float a, float b) { return std::max(a, b); });
				else std::transform(alignedimage.begin(), alignedimage.end(), meanimage[channelcount].begin(), meanimage[channelcount].begin(), std::plus<float>());
				count++;
			}
		}
		divisor = weights[channelcount];
		std::transform(meanimage[channelcount].begin(), meanimage[channelcount].end(), meanimage[channelcount].begin(), [divisor](auto x) { return x * divisor; });


		if (count > 0 && maxproject == false && normalize) std::transform(meanimage[channelcount].begin(), meanimage[channelcount].end(), meanimage[channelcount].begin(), [count](auto x) { return x / count; });
		
		if (channelcount > 0) {
			transformclass.transform(meanimage[channelcount], translated, -channelalignment[channelcount - 1][3], -channelalignment[channelcount - 1][4], channelalignment[channelcount - 1][1], channelalignment[channelcount - 1][2]);
			std::transform(translated.begin(), translated.end(), Combinedmeanimage.begin(), Combinedmeanimage.begin(), std::plus<float>());
		}
		else std::transform(meanimage[0].begin(), meanimage[0].end(), Combinedmeanimage.begin(), Combinedmeanimage.begin(), std::plus<float>());
	}

	if (normalize) std::transform(Combinedmeanimage.begin(), Combinedmeanimage.end(), Combinedmeanimage.begin(), [numInputFiles](auto x) { return x / numInputFiles; });
	

	string adjustedOutputFilename = outputfile + "_Partial_Mean.tiff";

	if(normalize)BLTiffIO::TiffOutput(adjustedOutputFilename, imageWidth, imageHeight, imageDepth).write1dImage(Combinedmeanimage);
	else BLTiffIO::TiffOutput(adjustedOutputFilename, imageWidth, imageHeight, 32).write1dImage(Combinedmeanimage);
		

	for (int i = 0; i < numInputFiles; i++)delete vcinput[i];
	//system("PAUSE");
	return 0;
}