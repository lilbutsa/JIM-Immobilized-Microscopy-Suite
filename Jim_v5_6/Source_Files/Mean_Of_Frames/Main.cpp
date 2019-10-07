#include <string>
#include <iostream>
#include <vector>
#include <algorithm>
#include "BLTiffIO.h"
#include "BLImageTransform.h"
#include "BLCSVIO.h"
#include "ipp.h"

using namespace std;

//Input should be align file, drift file, outfile, all image files, -Start chan1 chan2...,-End chan1, chan2
int main(int argc, char *argv[])
{
	int numInputFiles = 0;

	bool maxproject = false;

	for (int i = 4; i < argc && std::string(argv[i]) != "-Start"&& std::string(argv[i]) != "-End"&& std::string(argv[i]) != "-MaxProjection"; i++) numInputFiles++;


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



			for (int i = 1; i < argc; i++) {
				if (std::string(argv[i]) == "-Start") {
					for (int j = 0; j < numInputFiles; j++) {
						if (i + j + 1 < argc) {
							start[j] = stoi(argv[i + j + 1]) - 1;
							start[j] = max(start[j], 0);
							cout << "Calculating mean of channel " << j + 1 << " starting from frame " << start[j] + 1 << endl;
						}
						else { std::cout << "error inputting starts" << std::endl; return 1; }
					}
				}
				if (std::string(argv[i]) == "-End") {
					for (int j = 0; j < numInputFiles; j++) {
						if (i + j + 1 < argc) {
							end[j] = stoi(argv[i + j + 1]);
							end[j] = min(end[j], totnumofframes);
							cout << "Calculating mean of channel " << j + 1 << " ending at frame " << end[j] << endl;
						}
						else { std::cout << "error inputting ends" << std::endl; return 1; }
					}
				}
				if (std::string(argv[i]) == "-MaxProjection") {
					maxproject = true;
					cout << "Using Max Projection"<< endl;
				}
			}

			vector< vector<double> > drifts(3000, vector<double>(2, 0.0));
			std::vector<std::string> headerLine;
			BLCSVIO::readCSV(driftfile, drifts,headerLine);

			vector< vector<double> > channelalignment(11, vector<double>(2, 0.0));
			if (numInputFiles>1)BLCSVIO::readCSV(alignfile, channelalignment,headerLine);

			vector<float> alignedimage(imagePoints, 0.0);
			vector< vector<float> > meanimage(numInputFiles, vector<float>(imagePoints, 0.0));
			imageTransform_32f transformclass(imageWidth, imageHeight);

			IppiSize roiSize = { imageWidth,imageHeight };
			int srcStep = imageWidth * sizeof(float);

			vector<float> rotimage(imagePoints), scaleimage(imagePoints);
			vector<float> translated(imagePoints);

			vector<float>Combinedmeanimage = vector<float>(imagePoints, 0.0);

			float transxoffset, transyoffset;
			int count;
			for (int channelcount = 0; channelcount < numInputFiles; channelcount++) {
				count = 0;
				if (channelcount == 0) {
					for (int imcount = start[channelcount]; imcount < end[channelcount]; imcount++) {
						vcinput[channelcount]->read1dImage(imcount,image1);
						transformclass.imageTranslate(image1, alignedimage, -drifts[imcount][0], -drifts[imcount][1]);
						if (maxproject)ippsMaxEvery_32f_I(alignedimage.data(), meanimage[channelcount].data(), imagePoints);
						else ippiAdd_32f_C1IR(alignedimage.data(), srcStep, meanimage[channelcount].data(), srcStep, roiSize);
						count++;
					}

				}
				else {
					for (int imcount = start[channelcount]; imcount < end[channelcount]; imcount++) {
						transxoffset = (-drifts[imcount][0])*channelalignment[channelcount - 1][5] + (-drifts[imcount][1])*channelalignment[channelcount - 1][6];
						transyoffset = (-drifts[imcount][0])*channelalignment[channelcount - 1][7] + (-drifts[imcount][1])*channelalignment[channelcount - 1][8];
						vcinput[channelcount]->read1dImage(imcount, image1);
						transformclass.imageTranslate(image1, alignedimage, transxoffset, transyoffset);

						if (maxproject)ippsMaxEvery_32f_I(alignedimage.data(), meanimage[channelcount].data(), imagePoints);
						else ippiAdd_32f_C1IR(alignedimage.data(), srcStep, meanimage[channelcount].data(), srcStep, roiSize);
						
						count++;
					}
				}
				if (count>0 && maxproject==false)ippiMulC_32f_C1IR(1.0 / count, meanimage[channelcount].data(), srcStep, roiSize);

				if (channelcount > 0) {
					transformclass.transform(meanimage[channelcount], translated, channelalignment[channelcount - 1][1] * 3.14159 / 180.0, channelalignment[channelcount - 1][2], -channelalignment[channelcount - 1][3], -channelalignment[channelcount - 1][4]);
					ippiAdd_32f_C1IR(translated.data(), srcStep, Combinedmeanimage.data(), srcStep, roiSize);
				}
				else ippiAdd_32f_C1IR(meanimage[0].data(), srcStep, Combinedmeanimage.data(), srcStep, roiSize);
			}

			ippiMulC_32f_C1IR(1.0 / numInputFiles, Combinedmeanimage.data(), srcStep, roiSize);



			string adjustedOutputFilename = outputfile + "_Partial_Mean.tiff";

			BLTiffIO::TiffOutput(adjustedOutputFilename, imageWidth, imageHeight, imageDepth).write1dImage(Combinedmeanimage);
			
	//system("PAUSE");
	return 0;
}