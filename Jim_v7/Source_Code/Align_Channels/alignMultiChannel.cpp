#include "myHeader.hpp"

float findMedian(vector<float> datain) {
	size_t size = datain.size();
	sort(datain.begin(), datain.end());
	if (size % 2 == 0)
	{
		return (datain[size / 2 - 1] + datain[size / 2]) / 2;
	}
	else
	{
		return datain[size / 2];
	}
}

void alignMultiChannel(vector<string>& inputfilenames, int& start, int& end, int iterations, string outputfile, vector< vector<float> > &driftsout, int& imageWidth, float maxShift,vector<float>& maxIntensities,double SNRCutoff, vector< BLTiffIO::TiffOutput*>& outputFiles) {

	int numofChannels = inputfilenames.size();

	vector<float> initialmeanimage;
	vector< vector<float> > meanimage(numofChannels),notnormalised;
	vector< vector<float> > drifts;
	string adjustedOutputFilename;

	vector< BLTiffIO::TiffOutput*> dummy;

	for (int i = 0; i < numofChannels; i++) {
		std::cout << "Calculating initial drift for Channel " << i + 1 << "\n";
		driftCorrectSingleChannel(inputfilenames[i], start, end, iterations, initialmeanimage, meanimage[i], drifts, imageWidth,maxShift, dummy);

		adjustedOutputFilename = outputfile + "_initial_partial_mean_" + to_string(i + 1) + ".tiff";
		BLTiffIO::TiffOutput(adjustedOutputFilename, imageWidth, (uint32_t)initialmeanimage.size() / imageWidth, 16).write1dImage(initialmeanimage);

		adjustedOutputFilename = outputfile + "_initial_full_mean_" + to_string(i + 1) + ".tiff";
		BLTiffIO::TiffOutput(adjustedOutputFilename, imageWidth, (uint32_t)initialmeanimage.size() / imageWidth, 16).write1dImage(meanimage[i]);
	}

	uint32_t imagePoints = initialmeanimage.size();

	notnormalised = meanimage;

	Ipp32f mean, stddev;
	for (int i = 0; i < numofChannels; i++) {
		//Fix this line
		//ippsMeanStdDev_32f(meanimage[i].data(), imagePoints, &mean, &stddev, ippAlgHintFast);
		mean = findMedian(meanimage[i]);
		ippsThreshold_GTVal_32f_I(meanimage[i].data(), imagePoints, maxIntensities[i], mean);//Set upper threshold to ignore aggregates
		adjustedOutputFilename = outputfile + "_Thresholded_For_Channel_Alignment_" + to_string(i + 1) + ".tiff";
		BLTiffIO::TiffOutput(adjustedOutputFilename, imageWidth, (uint32_t)initialmeanimage.size() / imageWidth, 16).write1dImage(meanimage[i]);

		ippsMeanStdDev_32f(meanimage[i].data(), imagePoints, &mean, &stddev, ippAlgHintFast);
		ippsSubC_32f_I(mean, meanimage[i].data(), imagePoints);
		ippsDivC_32f_I(stddev, meanimage[i].data(), imagePoints);
	}


	//Finding Alignment


	alignImages_32f alignclass(10, imageWidth, imagePoints/imageWidth);
	imageTransform_32f transformclass(imageWidth, imagePoints / imageWidth);

	float xoffset, yoffset, maxangle, maxscale, maxcc;
	double deltain, hmaxscale, hmaxangle,backgroundcc;
	int maxcount;
	vector<float> vxoffset, vyoffset, vangle, vscale;

	vector< vector<float> > channelalignment(numofChannels-1,vector<float>(11,0));
	vector<float> combinedmean = meanimage[0];

	vector<float> imageout(21 * 21, 0.0);

	int ccwidth = 21;
	vector<vector<int>> edgepos = { {-2,-2},{-1,-2},{0,-2},{1,-2},{2,-2},{-2,-1},{2,-1},{-2,0},{2,0},{-2,1},{2,1},{-2,2},{-1,2},{0,2},{1,2},{2,2} };

	for (int i = 1; i < numofChannels; i++) {
		std::cout << "Aligning Channel " << i + 1 << endl;
		maxcc = 0;
		deltain =  10;
		maxscale = 1;
		maxangle = 0;
		maxcount = 0;

		for (int delta = 0; delta < 2; delta++) {
			deltain *= 0.1;
			hmaxscale = maxscale;
			hmaxangle = maxangle;

			int imagecount = 0;
			for (double scale = hmaxscale - 0.1*deltain; scale <= hmaxscale + 0.10001*deltain; scale = scale + 0.01*deltain)for (double angle = hmaxangle - 0.5*10 * deltain; angle <= hmaxangle + 0.5*10.0001 * deltain; angle = angle + 0.5*1 * deltain) {
				transformclass.transform(meanimage[i], initialmeanimage, angle*3.14159 / 180.0, scale, 0.0, 0.0);//ch
				alignclass.imageAligntopixel(meanimage[0], initialmeanimage, maxShift);

				imageout[imagecount] = alignclass.max1dval/10;

				if (alignclass.max1dval > maxcc) {
					maxcount = imagecount;
					maxcc = alignclass.max1dval;
					maxangle = angle;
					maxscale = scale;
					xoffset =  alignclass.offsetx;
					yoffset =  alignclass.offsety;

					//cout << "maxcc = " << maxcc << " max angle =  " << maxangle << " max scale = " << maxscale << "  x offset = " << xoffset << " y offset = " << yoffset << endl;

				}
				imagecount++;
			}

			if (delta == 0) {
				int backgroundcount = 0;
				int xmax = maxcount % ccwidth;
				int ymax = (int)maxcount / ccwidth;
				for (int boxcount = 0; boxcount < edgepos.size(); boxcount++) 
					if(xmax+edgepos[boxcount][0]>-1 && xmax + edgepos[boxcount][0] < ccwidth && ymax + edgepos[boxcount][1]>-1 && ymax + edgepos[boxcount][1] < ccwidth){
						backgroundcc += 10 * imageout[xmax + edgepos[boxcount][0] + ccwidth * (ymax + edgepos[boxcount][1])];
						backgroundcount++;
					}
				backgroundcc *= 1 / ((double)backgroundcount);
			}

			adjustedOutputFilename = outputfile + "_maxcc_" + to_string(delta) + ".tiff";
			BLTiffIO::TiffOutput(adjustedOutputFilename, ccwidth, ccwidth, 16).write1dImage(imageout);
		}

		//std::cout << "Channels Aligned \n";

		//cout << "maxcc = " << maxcc << " max angle =  " << maxangle << " max scale = " << maxscale << "  x offset = " << xoffset << " y offset = " << yoffset << endl;


		//std::cout << "transforms \n";
		transformclass.transform(meanimage[i], initialmeanimage, maxangle*3.14159 / 180.0, maxscale, 0, 0);
		alignclass.imageAlign(meanimage[0], initialmeanimage, maxShift);
		xoffset = alignclass.offsetx;
		yoffset = alignclass.offsety;

		std::cout << "Fit SNR = " << maxcc/backgroundcc << " max angle =  " << maxangle << " max scale = " << maxscale << "  x offset = " << xoffset << " y offset = " << yoffset << endl;

		if (maxcc / backgroundcc<SNRCutoff) {
			std::cout << "ALIGNMENT FAILED FOR CHANNEL " << i + 1 << ": SEEM TO BE FITTING NOISE - WILL IGNORE ALIGNMENT" << endl;
			std::cout << "See failed_alignment_channel_"<<i+1<<".tiff for visualisation" << endl;
			transformclass.transform(notnormalised[i], initialmeanimage, maxangle * 3.14159 / 180.0, maxscale, -xoffset, -yoffset);

			adjustedOutputFilename = outputfile + "_failed_alignment_channel_" + to_string(i + 1) + ".tiff";
			BLTiffIO::TiffOutput(adjustedOutputFilename, imageWidth, (uint32_t)initialmeanimage.size() / imageWidth, 16).write1dImage(initialmeanimage);

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

	vector< vector<float> > vecinitialmeanimage,vecfinalmeanimage;

	driftCorrectMultiChannel(inputfilenames, start, end, iterations, vangle, vscale, vxoffset, vyoffset, vecinitialmeanimage, vecfinalmeanimage, driftsout, imageWidth,maxShift, outputFiles);


	//Write images to file

	for (int i = 0; i < numofChannels; i++) {
		adjustedOutputFilename = outputfile + "_aligned_partial_mean_" + to_string(i + 1) + ".tiff";
		BLTiffIO::TiffOutput(adjustedOutputFilename, imageWidth, (uint32_t)initialmeanimage.size() / imageWidth, 16).write1dImage(vecinitialmeanimage[i]);

		adjustedOutputFilename = outputfile + "_aligned_full_mean_" + to_string(i + 1) + ".tiff";
		BLTiffIO::TiffOutput(adjustedOutputFilename, imageWidth, (uint32_t)initialmeanimage.size() / imageWidth, 16).write1dImage(vecfinalmeanimage[i]);
	}

	writeChannelAlignment(outputfile, vangle, vscale, vxoffset, vyoffset, imageWidth, initialmeanimage.size() / imageWidth);
}