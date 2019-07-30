#include "myHeader.h"


void driftCorrectSingleChannel(string& inputfilename, int& start, int& end,int iterations, vector<float>& initialmeanimage, vector<float>& finalmeanimage, vector<vector<float>> &driftsout, int& imageWidth) {

	BLTiffIO::TiffInput is(inputfilename);

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

				if(loopcount<iterations-1)alignclass.imageAligntopixel(imagetoalign, imagein);
				else alignclass.imageAlign(imagetoalign, imagein);

				transformclass.imageTranslate(imagein, imaget, -alignclass.offsetx, -alignclass.offsety);
				ippsAdd_32f_I(imaget.data(), finalmeanimage.data(), is.imagePoints);

				driftsout[imcount][0] = alignclass.offsetx;
				driftsout[imcount][1] = alignclass.offsety;
			}
			ippsDivC_32f_I((Ipp32f)is.numOfFrames, finalmeanimage.data(), is.imagePoints);
			//cout << endl;

			imagetoalign= finalmeanimage;

	}

	imageWidth = is.imageWidth;

}