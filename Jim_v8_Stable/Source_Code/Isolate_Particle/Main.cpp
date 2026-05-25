/*
 * Main.cpp - Isolate_Particle
 *
 * Description:
 *   This program creates a montage of a single particle's. It outputs an intensity-normalized montage 
 *   and optionally a TIFF stack of isolated regions-of-interest (ROIs) for the specified particle.
 *
 *
 * Core Functionality:
 *   - Loads image stacks, channel alignment matrices, drift correction data, and particle bounding boxes.
 *   - Applies spatial transformation (translation, affine alignment) to each frame.
 *   - Averages over specified frame ranges around each step to reduce noise.
 *   - Extracts and crops a bounding box around the particle, and assembles a montage.
 *   - Optionally outputs the time series of cropped images as a TIFF stack.
 *
 * Input Arguments (Positional):
 *   argv[1]  - Channel alignment CSV file (ignored if only one channel).
 *   argv[2]  - Drift correction CSV file (x, y drift per frame).
 *   argv[3]  - Particle measurement CSV file (bounding box metadata).
 *   argv[4]  - Output filename base (used for all output TIFFs).
 *   argv[5...] - One or more TIFF stacks (1 per channel, all same dimensions).
 *
 * Optional Flags:
 *   -Particle <int>   : Index of particle to isolate (1-based, default = 1)
 *   -Start <int>      : First frame to include (0-based, default = 0)
 *   -End <int>        : Last frame to include (exclusive, default = total number of frames)
 *   -Delta <int>      : Frame step between montage entries (default = 1)
 *   -Average <int>    : Number of frames to average around each montage frame (must be odd, default = 1)
 *   -OutputImageStack : Output a full aligned ROI stack as a TIFF
 *
 * Output Files:
 *   - <base>_Trace_<particle>_Range_<start>_<delta>_<end>_montage.tiff:
 *       A montage image of the aligned ROI over time (channels stacked vertically).
 *   - <base>_Trace_<particle>_Channel_<N>.tiff (optional):
 *       A TIFF stack of aligned ROI frames for channel N (only if -OutputImageStack is specified).
 *
 * Notes:
 *   - Pixel values are normalized using the 3rd to 97th percentile across all output frames for consistent contrast.
 *   - Alignment and drift correction are applied before cropping.
 *   - Output montage adds a 1-pixel border between tiles.
 *
 * Dependencies:
 *   - BLCSVIO: CSV file reader for measurement/alignment input.
 *   - BLTiffIO: TIFF I/O wrapper for reading multi-frame images and writing output.
 *   - BLImageTransform: Provides affine and translation operations on images.
 *   - BLFlagParser: Lightweight CLI flag parser.
 *
 * @author James Walsh james.walsh@phys.unsw.edu.au
 * @date 2025-07-14
 */


#include <string>
#include <iostream>
#include <vector>
#include <algorithm>
#include "BLTiffIO.h"
#include "BLImageTransform.h"
#include "BLCSVIO.h"
#include "BLFlagParser.h"

//Input should be align file, drift file, outfile, all image files, -Start chan1 chan2...,-End chan1, chan2
int main(int argc, char* argv[])
{


	if (argc == 1 || (std::string(argv[1]).substr(0, 2) == "-h" || std::string(argv[1]).substr(0, 2) == "-H")) {
		std::cout<<"Standard input: [channel alignment file] [Drift Correction File] [Particle Measurements File] [Output File Base] [Input Image Stack Channel 1]... Options\n";
		std::cout << "Options:\n";
		std::cout << "-Particle i (Default i = 1) Specify particle i to isolate\n";
		std::cout << "-Start i (Default i = 1) Specify frame i to start isolating from\n";
		std::cout << "-End i (Default i = total number of frames) Specify frame i to end isolating from\n";
		std::cout << "-Delta i (Default i = 1) Specify steps in frames between isolated images\n";
		std::cout << "-Average i (Default i = 1) Specify number of frames around each step to average image (Must Be Odd)\n";
		std::cout << "-outputImageStack Output the ROI for the particle as a tiff stack \n";
		return 0;
	}

	int numInputFiles = 0;
	int particle = 1, start = 0, end = 100000000, delta = 1, average = 1;
	int imageDepth, imageWidth, imageHeight, imagePoints, totnumofframes;
	std::vector< std::vector<double> > measurements(3000, std::vector<double>(19, 0.0)), drifts(3000, std::vector<double>(2, 0.0)), channelalignment(11, std::vector<double>(2, 0.0));
	std::string outputfile;
	std::vector<BLTiffIO::TiffInput*> vcinput;
	bool bOutputImageStack = false;

	try {
		if (argc<5)throw std::invalid_argument("Insufficient Arguments");
		for (int i = 5; i < argc && std::string(argv[i]).substr(0, 1) != "-"; i++) numInputFiles++;
		if(numInputFiles == 0)throw std::invalid_argument("No Input Image Stacks Detected");

		std::vector<std::string> headerLine;
		if (numInputFiles > 1)BLCSVIO::readCSV(argv[1], channelalignment, headerLine);
		BLCSVIO::readCSV(argv[2], drifts, headerLine);
		BLCSVIO::readCSV(argv[3], measurements, headerLine);

		outputfile = argv[4];

		std::vector<std::string> inputfiles(numInputFiles);
		for (int i = 0; i < numInputFiles; i++)inputfiles[i] = argv[i + 5];

		vcinput.resize(numInputFiles);
		for (int i = 0; i < numInputFiles; i++)vcinput[i] = new BLTiffIO::TiffInput(inputfiles[i]);
		imageDepth = vcinput[0]->imageDepth;
		imageWidth = vcinput[0]->imageWidth;
		imageHeight = vcinput[0]->imageHeight;
		imagePoints = imageWidth * imageHeight;
		totnumofframes = vcinput[0]->numOfFrames;
		end = totnumofframes;

		std::vector<std::pair<std::string, int*>> intFlags = { {"Particle", &particle},{"Start", &start},{"End", &end},{"Delta", &delta},{"Average", &average} };
		std::vector<std::pair<std::string, bool*>> boolFlags = { {"OutputAligned", &bOutputImageStack} };

		if (BLFlagParser::parseValues(intFlags, argc, argv)) return 1;
		if (BLFlagParser::parseValues(boolFlags, argc, argv)) return 1;

		particle = std::max(0, std::min(particle, (int)measurements.size()));
		start = std::max(start, 0);
		end = std::min(end, totnumofframes);
		if (average % 2 == 0)throw std::invalid_argument("Averaging Value Must Be Odd");
		average = (average - 1) / 2;

	}
	catch (const std::invalid_argument & e) {
		std::cout << "Error Inputting Parameters\n";
		std::cout << e.what() << "\n";
		std::cout << "See -Help for help\n";
		return 1;
	}



	std::vector<float> image1(imagePoints), alignedimage(imagePoints, 0.0);
	
	uint32_t numOutputImages =floor( ((end - start) / delta)+1);
	uint32_t outputStart = (measurements[particle - 1][14]-3) + (measurements[particle - 1][16]-3) * imageWidth;
	uint32_t outputWidth = measurements[particle - 1][15] - measurements[particle - 1][14] + 7;
	uint32_t outputHeight = measurements[particle - 1][17] - measurements[particle - 1][16] + 7;
	uint32_t outputImagePoints = outputWidth * outputHeight;
	uint32_t outputMontageWidth = (outputWidth + 2) * numOutputImages;
	uint32_t outputMontagePoints = (outputWidth + 2) * (outputHeight + 2) * numOutputImages * numInputFiles;

	std::vector<float> montage(outputMontagePoints, 65000);

	//vector< vector<float>> avimageout( numOutputImages, vector<float>(outputImagePoints, 0.0));
	//vector<float> flattenedimout(outputImagePoints * numOutputImages, 0.0);

	
	std::vector<float> translated(imagePoints);
	int CountImAveraged;
	float transxoffset, transyoffset;

	imageTransform_32f transformclass(imageWidth, imageHeight);
	std::vector<float> imagein(imagePoints), imaget(imagePoints),singleFrame(outputImagePoints);
	std::vector< std::vector<float> > outputImageStack(numOutputImages, std::vector<float>(outputImagePoints));
	
	BLTiffIO::TiffOutput* tiffout = NULL;

	//BLTiffIO::TiffOutput troubleshooting(outputfile + "troubleshooting.tiff", imageWidth, imageHeight, imageDepth, false);
	for (int chancount = 0; chancount < numInputFiles; chancount++) {
		std::cout << "Starting Output for Channel "<< std::to_string(chancount+1)<<"\n";

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
						transformclass.transform(imagein, imaget, -channelalignment[chancount - 1][3], -channelalignment[chancount - 1][4], channelalignment[chancount - 1][1] , channelalignment[chancount - 1][2]);
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
				transformclass.transform(imagein, imaget,  -channelalignment[chancount - 1][3], -channelalignment[chancount - 1][4], channelalignment[chancount - 1][1] , channelalignment[chancount - 1][2]);
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

			if(bOutputImageStack && tiffout!=NULL)tiffout->write1dImage(singleFrame);

		}

		if (bOutputImageStack && tiffout != NULL) delete tiffout;
	}



	BLTiffIO::TiffOutput(outputfile + "_Trace_" + std::to_string(particle) + "_Range_" + std::to_string(start + 1) + "_" + std::to_string(delta) + "_" + std::to_string(end) + "_montage.tiff", outputMontageWidth, (outputHeight + 2) * numInputFiles, 16, false).write1dImage(montage);


	for (int i = 0; i < numInputFiles; i++)delete vcinput[i];
	return 0;
}