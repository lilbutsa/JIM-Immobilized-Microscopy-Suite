#include "myHeader.h"


void alignMultiChannel(vector<string>& inputfilenames, int& start, int& end, int iterations, string outputfile, vector<vector<float>> &driftsout, int& imageWidth) {

	int numofChannels = inputfilenames.size();

	vector<float> initialmeanimage;
	vector<vector<float>> meanimage(numofChannels);
	vector<vector<float>> drifts;
	string adjustedOutputFilename;

	for (int i = 0; i < numofChannels; i++) {
		std::cout << "Calculating initial drift for Channel " << i + 1 << "\n";
		driftCorrectSingleChannel(inputfilenames[i], start, end, iterations, initialmeanimage, meanimage[i], drifts, imageWidth);

		adjustedOutputFilename = outputfile + "_initial_partial_mean_" + to_string(i + 1) + ".tiff";
		BLTiffIO::TiffOutput(adjustedOutputFilename, imageWidth, (uint32_t)initialmeanimage.size() / imageWidth, 16).write1dImage(initialmeanimage);

		adjustedOutputFilename = outputfile + "_initial_full_mean_" + to_string(i + 1) + ".tiff";
		BLTiffIO::TiffOutput(adjustedOutputFilename, imageWidth, (uint32_t)initialmeanimage.size() / imageWidth, 16).write1dImage(meanimage[i]);
	}

	uint32_t imagePoints = initialmeanimage.size();

	Ipp32f mean, stddev;
	for (int i = 0; i < numofChannels; i++) {
		ippsMeanStdDev_32f(meanimage[i].data(), imagePoints, &mean, &stddev, ippAlgHintFast);
		ippsSubC_32f_I(mean, meanimage[i].data(), imagePoints);
		ippsDivC_32f_I(stddev, meanimage[i].data(), imagePoints);
	}


	//Finding Alignment


	alignImages_32f alignclass(10, imageWidth, imagePoints/imageWidth);
	imageTransform_32f transformclass(imageWidth, imagePoints / imageWidth);

	float xoffset, yoffset, maxangle, maxscale, maxcc, deltain, hmaxscale, hmaxangle;
	vector<float> vxoffset, vyoffset, vangle, vscale;

	vector<vector<float>> channelalignment(numofChannels-1,vector<float>(11,0));
	vector<float> combinedmean = meanimage[0];


	for (int i = 1; i < numofChannels; i++) {
		std::cout << "Aligning Channel " << i + 1 << endl;
		maxcc = 0;
		deltain = 10;
		maxscale = 1;
		maxangle = 0;

		for (int delta = 0; delta < 3; delta++) {
			deltain *= 0.1;
			hmaxscale = maxscale;
			hmaxangle = maxangle;


			for (double scale = hmaxscale - 0.1*deltain; scale <= hmaxscale + 0.1*deltain; scale = scale + 0.01*deltain)for (double angle = hmaxangle - 10 * deltain; angle <= hmaxangle + 10 * deltain; angle = angle + 1 * deltain) {
				transformclass.transform(meanimage[i], initialmeanimage, angle*3.14159 / 180.0, scale, 0.0, 0.0);//ch
				alignclass.imageAligntopixel(meanimage[0], initialmeanimage);

				if (alignclass.max1dval > maxcc) {
					maxcc = alignclass.max1dval;
					maxangle = angle;
					maxscale = scale;
					xoffset =  alignclass.offsetx;
					yoffset =  alignclass.offsety;

					//cout << "maxcc = " << maxcc << " max angle =  " << maxangle << " max scale = " << maxscale << "  x offset = " << xoffset << " y offset = " << yoffset << endl;

				}
			}

		}

		//cout << "maxcc = " << maxcc << " max angle =  " << maxangle << " max scale = " << maxscale << "  x offset = " << xoffset << " y offset = " << yoffset << endl;

		if (abs(maxangle) > 10 || abs(maxscale - 1) >100 * 0.1) {
			std::cout << "WARNING SEEM TO BE FITTING NOISE:WILL IGNORE ROTATION AND SCALING" << endl;
			maxcc = 0;
			maxangle = 0;
			maxscale = 1;
		}

		transformclass.transform(meanimage[i], initialmeanimage, maxangle*3.14159 / 180.0, maxscale, 0, 0);
		alignclass.imageAlign(meanimage[0], initialmeanimage);
		xoffset = alignclass.offsetx;
		yoffset = alignclass.offsety;

		std::cout << "maxcc = " << maxcc << " max angle =  " << maxangle << " max scale = " << maxscale << "  x offset = " << xoffset << " y offset = " << yoffset << endl;

		if (abs(xoffset) > 40 || abs(yoffset) > 40) {
			std::cout << "alignment failed" << endl;
			maxcc = 0;
			maxangle = 0;
			maxscale = 1;
			xoffset = 0;
			yoffset = 0;
		}

		vxoffset.push_back(xoffset);
		vyoffset.push_back(yoffset);
		vscale.push_back(maxscale);
		vangle.push_back(maxangle);

	}


	cout << "Calculating final combined drifts\n";

	vector<vector<float>> vecinitialmeanimage,vecfinalmeanimage;

	driftCorrectMultiChannel(inputfilenames, start, end, iterations, vangle, vscale, vxoffset, vyoffset, vecinitialmeanimage, vecfinalmeanimage, driftsout, imageWidth);


	//Write images to file

	for (int i = 0; i < numofChannels; i++) {
		adjustedOutputFilename = outputfile + "_aligned_partial_mean_" + to_string(i + 1) + ".tiff";
		BLTiffIO::TiffOutput(adjustedOutputFilename, imageWidth, (uint32_t)initialmeanimage.size() / imageWidth, 16).write1dImage(vecinitialmeanimage[i]);

		adjustedOutputFilename = outputfile + "_aligned_full_mean_" + to_string(i + 1) + ".tiff";
		BLTiffIO::TiffOutput(adjustedOutputFilename, imageWidth, (uint32_t)initialmeanimage.size() / imageWidth, 16).write1dImage(vecfinalmeanimage[i]);
	}

	writeChannelAlignment(outputfile, vangle, vscale, vxoffset, vyoffset, imageWidth, initialmeanimage.size() / imageWidth);
}