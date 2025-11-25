#include <string>
#include <iostream>
#include <vector>
#include <algorithm>
#include "BLTiffIO.h"
#include "BLImageTransform.h"
#include "BLCSVIO.h"

int Isolate_Particle(std::string outputfile, std::vector<std::string> inputfiles, std::string driftfile, std::string alignfile, std::string measurementsfile, int particle, int start, int end, int delta, int average, bool bOutputImageStack) {


	std::vector<BLTiffIO::TiffInput*> vcinput(inputfiles.size());
	for (int i = 0; i < inputfiles.size(); i++)vcinput[i] = new BLTiffIO::TiffInput(inputfiles[i]);
	
	int imageDepth = vcinput[0]->imageDepth;
	int imageWidth = vcinput[0]->imageWidth;
	int imageHeight = vcinput[0]->imageHeight;
	int imagePoints = imageWidth * imageHeight;
	int totnumofframes = vcinput[0]->numOfFrames;

	average = (average - 1) / 2;

	std::vector< std::vector<double> > measurements(3000, std::vector<double>(19, 0.0)), drifts(3000, std::vector<double>(2, 0.0)), channelalignment(11, std::vector<double>(2, 0.0));
	std::vector<std::string> headerLine;
	if (inputfiles.size() > 1)BLCSVIO::readCSV(alignfile, channelalignment, headerLine);
	BLCSVIO::readCSV(driftfile, drifts, headerLine);
	BLCSVIO::readCSV(measurementsfile, measurements, headerLine);

	particle = std::max(0, std::min(particle, (int)measurements.size())); 
	start = std::max(start, 0);
	end = std::min(end, totnumofframes);

	std::vector<float> image1(imagePoints), alignedimage(imagePoints, 0.0);

	uint32_t numOutputImages = floor(((end - start) / delta) + 1);
	uint32_t outputStart = (measurements[particle - 1][14] - 3) + (measurements[particle - 1][16] - 3) * imageWidth;
	uint32_t outputWidth = measurements[particle - 1][15] - measurements[particle - 1][14] + 7;
	uint32_t outputHeight = measurements[particle - 1][17] - measurements[particle - 1][16] + 7;
	uint32_t outputImagePoints = outputWidth * outputHeight;
	uint32_t outputMontageWidth = (outputWidth + 2) * numOutputImages;
	uint32_t outputMontagePoints = (outputWidth + 2) * (outputHeight + 2) * numOutputImages * inputfiles.size();

	std::vector<float> montage(outputMontagePoints, 65000);

	//vector< vector<float>> avimageout( numOutputImages, vector<float>(outputImagePoints, 0.0));
	//vector<float> flattenedimout(outputImagePoints * numOutputImages, 0.0);


	std::vector<float> translated(imagePoints);
	int CountImAveraged;
	float transxoffset, transyoffset;

	imageTransform_32f transformclass(imageWidth, imageHeight);
	std::vector<float> imagein(imagePoints), imaget(imagePoints), singleFrame(outputImagePoints);
	std::vector< std::vector<float> > outputImageStack(numOutputImages, std::vector<float>(outputImagePoints));

	BLTiffIO::TiffOutput* tiffout = NULL;

	//BLTiffIO::TiffOutput troubleshooting(outputfile + "troubleshooting.tiff", imageWidth, imageHeight, imageDepth, false);
	for (int chancount = 0; chancount < inputfiles.size(); chancount++) {
		std::cout << "Starting Output for Channel " << std::to_string(chancount + 1) << "\n";

		if (bOutputImageStack) {
			std::string fileOutName = outputfile + "_Trace_" + std::to_string(particle) + "_Channel_" + std::to_string(chancount + 1) + ".tiff";
			std::cout << fileOutName << "\n";
			tiffout = new BLTiffIO::TiffOutput(fileOutName, outputWidth, outputHeight, imageDepth, false);
		}
		//BLTiffIO::TiffOutput tiffout(fileOutName, imageWidth, imageHeight, imageDepth, false);

		for (int imcount = 0; imcount < numOutputImages; imcount++) {
			std::vector<float> meanimage(imagePoints, 0.0);
			CountImAveraged = 0;
			for (int avcount = -average; avcount <= average; avcount++) {
				int iminnum = start + imcount * delta + avcount;
				if (iminnum >= 0 && iminnum < totnumofframes) {
					vcinput[chancount]->read1dImage(iminnum, imagein);

					if (chancount > 0) {
						//cout << channelalignment[chancount - 1][1] << " " << channelalignment[chancount - 1][2] << "\n";
						transformclass.transform(imagein, imaget, -channelalignment[chancount - 1][3], -channelalignment[chancount - 1][4], channelalignment[chancount - 1][1], channelalignment[chancount - 1][2]);
						imagein = imaget;
					}
					//cout << drifts[iminnum][0] << " " << drifts[iminnum][1] << "\n";
					transformclass.translate(imagein, imaget, -drifts[iminnum][0], -drifts[iminnum][1]);

					std::transform(imaget.begin(), imaget.end(), meanimage.begin(), meanimage.begin(), std::plus<float>());

					CountImAveraged++;
				}
			}
			std::transform(meanimage.begin(), meanimage.end(), meanimage.begin(), [CountImAveraged](auto x) { return x / CountImAveraged; });

			for (int i = 0; i < outputWidth; i++)for (int j = 0; j < outputHeight; j++) {
				uint32_t pos = outputStart + i + j * imageWidth;
				if (pos > 0 && pos < imagePoints) {
					outputImageStack[imcount][i + j * outputWidth] = meanimage[pos];
				}
			}

			//tiffout.write1dImage(outputImageStack[imcount]);
			//tiffout.write1dImage(meanimage);
		}


		//make the montage
		std::vector<float> flattenedimout;
		for (auto const& v : outputImageStack) {
			flattenedimout.insert(flattenedimout.end(), v.begin(), v.end());
		}
		std::sort(flattenedimout.begin(), flattenedimout.end());
		float mymin = flattenedimout[round(0.03 * outputImagePoints * numOutputImages)];
		float mymax = flattenedimout[round(0.97 * outputImagePoints * numOutputImages)];

		for (int imcount = 0; imcount < numOutputImages; imcount++)
			for (int i = 0; i < outputWidth; i++)for (int j = 0; j < outputHeight; j++) {
				uint16_t pos = (outputWidth + 2) * (outputHeight + 2) * numOutputImages * chancount;
				pos += (outputWidth + 2) * imcount + i + 1 + (j + 1) * outputMontageWidth;
				float toout = outputImageStack[imcount][i + j * outputWidth];
				montage[pos] = std::max(std::min(65000 * (toout - mymin) / (mymax - mymin), (float)65000), (float)1);
			}


		//output full stacks for particle

		for (int imcount = 0; imcount < totnumofframes; imcount++) {

			vcinput[chancount]->read1dImage(imcount, imagein);

			if (chancount > 0) {
				//cout << channelalignment[chancount - 1][1] << " " << channelalignment[chancount - 1][2] << "\n";
				transformclass.transform(imagein, imaget, -channelalignment[chancount - 1][3], -channelalignment[chancount - 1][4], channelalignment[chancount - 1][1], channelalignment[chancount - 1][2]);
				imagein = imaget;
			}
			//cout << drifts[iminnum][0] << " " << drifts[iminnum][1] << "\n";
			transformclass.translate(imagein, imaget, -drifts[imcount][0], -drifts[imcount][1]);

			for (int i = 0; i < outputWidth; i++)for (int j = 0; j < outputHeight; j++) {
				uint32_t pos = outputStart + i + j * imageWidth;
				if (pos > 0 && pos < imagePoints) {
					float toout = imaget[pos];
					singleFrame[i + j * outputWidth] = std::max(std::min(65000 * (toout - mymin) / (mymax - mymin), (float)65000), (float)1);
				}
			}

			if (bOutputImageStack && tiffout != NULL)tiffout->write1dImage(singleFrame);

		}

		if (bOutputImageStack && tiffout != NULL) delete tiffout;
	}



	BLTiffIO::TiffOutput(outputfile + "_Trace_" + std::to_string(particle) + "_Range_" + std::to_string(start + 1) + "_" + std::to_string(delta) + "_" + std::to_string(end) + "_montage.tiff", outputMontageWidth, (outputHeight + 2) * inputfiles.size(), 16, false).write1dImage(montage);


	for (int i = 0; i < inputfiles.size(); i++)delete vcinput[i];


}