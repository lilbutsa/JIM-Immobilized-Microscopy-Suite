#include "myHeader.h"


void driftCorrectSingleChannel(string& inputfilename, int& start, int& end,int iterations, vector<float>& initialmeanimage, vector<float>& finalmeanimage, vector<vector<float>> &driftsout, int& imageWidth) {

	BLTiffIO::TiffInput is(inputfilename);

	imageWidth = is.imageWidth;

	if (start < 0)start = 0;
	if (end > is.numOfFrames) {
		end = is.numOfFrames;
		std::cout << "End frame set to end of image stack (frame " << end << ")\n";
	}

	vector<float> imagein(is.imagePoints, 0), imaget(is.imagePoints, 0), imagetoalign(is.imagePoints, 0);

	finalmeanimage.resize(is.imagePoints);

	driftsout.resize(is.numOfFrames);
	for (int i = 0; i < is.numOfFrames; i++)driftsout[i].resize(2);

	cout << "Creating Initial Mean " << endl;

	for (int imcount = start; imcount < end; imcount++) {
		is.read1dImage(imcount, imagein);
		ippsAdd_32f_I(imagein.data(), imagetoalign.data(), is.imagePoints);
	}
	ippsDivC_32f_I((Ipp32f)(end - start + 1), imagetoalign.data(), is.imagePoints);

	vector<float> gaussblurred(is.imagePoints, 0);
	IppiSize roiSize = { is.imageWidth, is.imageHeight };
	Ipp32u kernelSize = 5;
	int iTmpBufSize = 0, iSpecSize = 0;
	ippiFilterGaussianGetBufferSize(roiSize, kernelSize, ipp32f, 1, &iSpecSize, &iTmpBufSize);
	IppFilterGaussianSpec* pSpec = (IppFilterGaussianSpec *)ippsMalloc_8u(iSpecSize);
	Ipp8u* pBuffer = ippsMalloc_8u(iTmpBufSize);
	ippiFilterGaussianInit(roiSize, kernelSize, 2.5, ippBorderRepl, ipp32f, 1, pSpec, pBuffer);

	ippiFilterGaussianBorder_32f_C1R(imagetoalign.data(), is.imageWidth * sizeof(Ipp32f), gaussblurred.data(), is.imageWidth * sizeof(Ipp32f), roiSize, ippBorderRepl, pSpec, pBuffer);
	imagetoalign = gaussblurred;

	initialmeanimage = imagetoalign;

	//END CREATING INITIAL MEAN

	alignImages_32f alignclass(10, is.imageWidth, is.imageHeight);
	imageTransform_32f transformclass(is.imageWidth, is.imageHeight);
	
	cout << "Creating secondary Mean " << endl;

	for (int loopcount = 0; loopcount < iterations; loopcount++) {
		cout << "Iteration " << loopcount + 1 << endl;
		std::fill(finalmeanimage.begin(), finalmeanimage.end(), 0.0);
			for (int imcount = 0; imcount < is.numOfFrames; imcount++) {
				is.read1dImage(imcount, imagein);

				if(loopcount<iterations-1){alignclass.imageAlign(imagetoalign, imagein);
				}
				else { 
					alignclass.imageAlign(imagetoalign, imagein);
					driftsout[imcount][0] = alignclass.offsetx;
					driftsout[imcount][1] = alignclass.offsety;
				}

				transformclass.imageTranslate(imagein, imaget, -alignclass.offsetx, -alignclass.offsety);
				ippsAdd_32f_I(imaget.data(), finalmeanimage.data(), is.imagePoints);


			}
			ippsDivC_32f_I((Ipp32f)is.numOfFrames, finalmeanimage.data(), is.imagePoints);
			//cout << endl;

			imagetoalign= finalmeanimage;
			ippiFilterGaussianBorder_32f_C1R(imagetoalign.data(), is.imageWidth * sizeof(Ipp32f), gaussblurred.data(), is.imageWidth * sizeof(Ipp32f), roiSize, ippBorderRepl, pSpec, pBuffer);
			imagetoalign = gaussblurred;

	}

	

}