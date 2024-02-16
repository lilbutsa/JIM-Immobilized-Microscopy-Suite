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

void alignMultiChannel(vector<BLTiffIO::TiffInput*> is, uint32_t start, uint32_t end, uint32_t iterations, uint32_t maxShift, string fileBase, bool bOutputStack, vector<float>& maxIntensities, double SNRCutoff,bool bSkipIndependentDrifts) {
	

	uint32_t imageWidth = is[0]->imageWidth;
	uint32_t imageHeight = is[0]->imageHeight;
	uint32_t imagePoints = imageWidth * imageHeight;
	uint32_t numOfFrames = is[0]->numOfFrames;
	uint32_t numOfChan = is.size();
	string adjustedOutputFilename;


	vector< vector<float> > meanimage(numOfChan, vector<float>(imagePoints,0.0)), notnormalised;
	vector<float> imagein(imagePoints), imaget(imagePoints);

	if (bSkipIndependentDrifts==false) {
		for (int i = 0; i < numOfChan; i++) {
			std::cout << "Calculating initial drift for Channel " << i + 1 << "\n";
			adjustedOutputFilename = fileBase + "_Channel_" + to_string(i + 1) + "_Drift.csv";
			driftCorrect({ is[i] }, { {} }, start, end, iterations, maxShift, "", false, meanimage[i], adjustedOutputFilename);
			//driftCorrect({ is[i] }, { {} }, start, end, iterations, maxShift, fileBase + "Troubleshooting" + to_string(i + 1), true, meanimage[i], adjustedOutputFilename);

		}
	}
	else {
		for (int i = 0; i < numOfChan; i++) {
			for (int j = start; j < end; j++) {
				is[i]->read1dImage(j, imagein);
				ippsAdd_32f_I(imagein.data(), meanimage[i].data(), is[0]->imagePoints);
			}
			ippsDivC_32f_I((Ipp32f)(end - start + 1), meanimage[i].data(), is[0]->imagePoints);
		}
	}

	notnormalised = meanimage;

	IppiSize roiSize = { imageWidth, imageHeight };
	int sizeDFTSpec, sizeDFTInitBuf, sizeDFTWorkBuf;
	ippiDFTGetSize_R_32f(roiSize, IPP_FFT_DIV_INV_BY_N, ippAlgHintAccurate, &sizeDFTSpec, &sizeDFTInitBuf, &sizeDFTWorkBuf);
	// Alloc DFT buffers
	IppiDFTSpec_R_32f* pDFTSpec = (IppiDFTSpec_R_32f*)ippsMalloc_8u(sizeDFTSpec);
	Ipp8u* pDFTInitBuf = ippsMalloc_8u(sizeDFTInitBuf);
	Ipp8u* pDFTWorkBuf = ippsMalloc_8u(sizeDFTWorkBuf);

	// Initialize DFT
	ippiDFTInit_R_32f(roiSize, IPP_FFT_DIV_INV_BY_N, ippAlgHintAccurate, pDFTSpec, pDFTInitBuf);
	if (pDFTInitBuf) ippFree(pDFTInitBuf);
	std::vector<float> fourier(imagePoints);



	adjustedOutputFilename = fileBase + "_Images_To_Align.tiff";
	//BLTiffIO::TiffOutput thresholdStack(adjustedOutputFilename, imageWidth, imageHeight, 16);
	Ipp32f mean, stddev;
	for (int i = 0; i < numOfChan; i++) {
		//mean = findMedian(meanimage[i]);
		//ippsThreshold_GTVal_32f_I(meanimage[i].data(), imagePoints, maxIntensities[i], mean);//Set upper threshold to ignore aggregates
		//thresholdStack.write1dImage(meanimage[i]);

		ippiDFTFwd_RToPack_32f_C1R(meanimage[i].data(), imageWidth * sizeof(float), fourier.data(), imageWidth * sizeof(float), pDFTSpec, pDFTWorkBuf);
		for (int j = 0; j < 11; j++)for (int k = 0; k < 11; k++) {
			if (j != 0 || k != 0)fourier[j + imageWidth * k] = 0;
		}

		ippiDFTInv_PackToR_32f_C1R(fourier.data(), imageWidth * sizeof(float), meanimage[i].data(), imageWidth * sizeof(float), pDFTSpec, pDFTWorkBuf);

		//thresholdStack.write1dImage(meanimage[i]);




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
	vector<float> vSNR;


	vector< vector<float> > channelalignment(numOfChan-1,vector<float>(4,0));
	vector<float> combinedmean = meanimage[0];

	vector<float> imageout(21 * 21, 0.0);

	int ccwidth = 21;
	vector<vector<int>> edgepos = { {-2,-2},{-1,-2},{0,-2},{1,-2},{2,-2},{-2,-1},{2,-1},{-2,0},{2,0},{-2,1},{2,1},{-2,2},{-1,2},{0,2},{1,2},{2,2} };
	//cout << "maxshift = " << maxShift << "\n";
	for (int i = 1; i < numOfChan; i++) {
		std::cout << "Aligning Channel " << i + 1 << endl;
		maxcc = 0;
		deltain =  10;
		maxscale = 1;
		maxangle = 0;
		maxcount = 0;

		alignclass.preloadImage(meanimage[0]);

		for (int delta = 0; delta < 2; delta++) {
			deltain *= 0.1;
			hmaxscale = maxscale;
			hmaxangle = maxangle;

			int imagecount = 0;

			//cout << "min angle = " << (hmaxangle - 0.5 * 10 * deltain) << " \n";
			//cout << "max angle = " << (hmaxangle + 0.5 * 10 * deltain)  << " \n";
			//cout << "mid angle = " << hmaxangle << " \n";
			for (double scale = hmaxscale - 0.1*deltain; scale <= hmaxscale + 0.10001*deltain; scale = scale + 0.01*deltain)for (double angle = hmaxangle - 0.5*10 * deltain; angle <= hmaxangle + 0.5*10.0001 * deltain; angle = angle + 0.5*1 * deltain) {
				transformclass.transform(meanimage[i], imaget, angle*3.14159 / 180.0, scale, 0.0, 0.0);//ch
				alignclass.imageAligntopixelpreloaded(imaget, maxShift);
				//else alignclass.imageAlign(meanimage[0], imaget, maxShift);
				//alignclass.imageAlign(meanimage[0], imaget, maxShift);

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
				//cout << "maxcc = " << alignclass.max1dval << " max angle =  " << angle << " max scale = " << scale << "  x offset = " << alignclass.offsetx << " y offset = " << alignclass.offsety << endl;
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

			//adjustedOutputFilename = fileBase + "_maxcc_" + to_string(delta) + ".tiff";
			//BLTiffIO::TiffOutput(adjustedOutputFilename, ccwidth, ccwidth, 16).write1dImage(imageout);
		}



		//std::cout << "transforms \n";
		transformclass.transform(meanimage[i], imaget, maxangle*3.14159 / 180.0, maxscale, 0, 0);
		alignclass.imageAlign(meanimage[0], imaget, maxShift);
		xoffset = alignclass.offsetx;
		yoffset = alignclass.offsety;

		std::cout << "Fit SNR = " << maxcc/backgroundcc << "  x offset = " << xoffset << " y offset = " << yoffset << " max angle =  " << maxangle << " max scale = " << maxscale  << endl;

		channelalignment[i-1][0] = xoffset;
		channelalignment[i-1][1] = yoffset;
		channelalignment[i-1][2] = maxangle;
		channelalignment[i-1][3] = maxscale;
		
		vSNR.push_back(maxcc / backgroundcc);
	}

	if (*min_element(vSNR.begin(), vSNR.end())<SNRCutoff) {

		adjustedOutputFilename = fileBase + "_failed_alignment.tiff";
		BLTiffIO::TiffOutput errorStack(adjustedOutputFilename, imageWidth, imageHeight, 16);
		for (int i = 0; i < numOfChan; i++) {
			if (i == 0)imaget = notnormalised[i];
			else transformclass.transform(notnormalised[i], imaget, channelalignment[i - 1][2] * 3.14159 / 180.0, channelalignment[i - 1][3], -channelalignment[i - 1][0], -channelalignment[i - 1][1]);
			errorStack.write1dImage(imaget);
		}
		throw std::invalid_argument("ALIGNMENT FAILED FOR CHANNEL " + to_string(std::min_element(vSNR.begin(), vSNR.end()) - vSNR.begin()+2) + " with SNR = " + to_string(*min_element(vSNR.begin(), vSNR.end())) + "\nSee failed_alignment.tiff for visualisation\n");
	}


	adjustedOutputFilename = fileBase + "_Combined_Drift.csv";
	driftCorrect(is, channelalignment, start, end, iterations, maxShift, fileBase, bOutputStack, meanimage[0], adjustedOutputFilename);

	writeChannelAlignment(fileBase, channelalignment, is[0]->imageWidth, is[0]->imageHeight);

}