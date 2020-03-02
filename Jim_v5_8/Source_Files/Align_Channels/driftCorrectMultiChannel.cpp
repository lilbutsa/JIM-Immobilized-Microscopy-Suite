#include "myHeader.hpp"


void driftCorrectMultiChannel(vector<string>& inputfilename, int& start, int& end, int iterations, vector<float>&angle, vector<float>&scale, vector<float>&xoffset, vector<float>&yoffset,vector< vector<float> >& initialmeanimage, vector< vector<float> >& finalmeanimage, vector< vector<float> > &driftsout, int& imageWidth) {

	int numInputFiles = inputfilename.size();

	vector<BLTiffIO::TiffInput*> vis(numInputFiles);
	for (int i = 0; i < numInputFiles; i++)vis[i] = new BLTiffIO::TiffInput(inputfilename[i]);

	imageWidth = vis[0]->imageWidth;

	if (start < 0)start = 0;
	if (end > vis[0]->numOfFrames) {
		end = vis[0]->numOfFrames;
		std::cout << "End frame set to end of image stack (frame " << end << ")\n";
	}

	vector<float> imagein(vis[0]->imagePoints, 0), imaget(vis[0]->imagePoints, 0), imagetoalign(vis[0]->imagePoints, 0) , combimage(vis[0]->imagePoints, 0), alignedimage(vis[0]->imagePoints, 0);

	//finalmeanimage = vector<float>(vis[0]->imagePoints);
	driftsout.resize(vis[0]->numOfFrames);
	for (int i = 0; i < vis[0]->numOfFrames; i++)driftsout[i].resize(2);

	alignImages_32f alignclass(10, vis[0]->imageWidth, vis[0]->imageHeight);
	imageTransform_32f transformclass(vis[0]->imageWidth, vis[0]->imageHeight);

	cout << "Creating Initial Mean " << endl;
	initialmeanimage.resize(numInputFiles);
	for (int i = 0; i < numInputFiles; i++)initialmeanimage[i] = vector<float>(vis[0]->imagePoints, 0.0);
	finalmeanimage.resize(numInputFiles);
	for (int i = 0; i < numInputFiles; i++)finalmeanimage[i] = vector<float>(vis[0]->imagePoints, 0.0);

	for(int chancount = 0;chancount<numInputFiles;chancount++)
	for (int imcount = start; imcount < end; imcount++) {
		if(chancount==0)vis[0]->read1dImage(imcount, imaget);
		else {
			vis[chancount]->read1dImage(imcount, imagein);
			transformclass.transform(imagein, imaget, angle[chancount-1]*3.14159 / 180.0, scale[chancount-1], -xoffset[chancount-1], -yoffset[chancount-1]);
		}
		ippsAdd_32f_I(imaget.data(), initialmeanimage[chancount].data(), vis[0]->imagePoints);
	}
	for (int i = 0; i < numInputFiles; i++) {
		ippsDivC_32f_I((Ipp32f)(end - start + 1), initialmeanimage[i].data(), vis[0]->imagePoints);
		ippsAdd_32f_I(initialmeanimage[i].data(), imagetoalign.data(), vis[0]->imagePoints);
	}

	ippsDivC_32f_I((Ipp32f)numInputFiles, imagetoalign.data(), vis[0]->imagePoints);


	vector<float> gaussblurred(vis[0]->imagePoints, 0);

	int imageHeight = vis[0]->imageHeight;

	IppiSize roiSize = { imageWidth, imageHeight };
	Ipp32u kernelSize = 5;
	int iTmpBufSize = 0, iSpecSize = 0;
	ippiFilterGaussianGetBufferSize(roiSize, kernelSize, ipp32f, 1, &iSpecSize, &iTmpBufSize);
	IppFilterGaussianSpec* pSpec = (IppFilterGaussianSpec *)ippsMalloc_8u(iSpecSize);
	Ipp8u* pBuffer = ippsMalloc_8u(iTmpBufSize);
	ippiFilterGaussianInit(roiSize, kernelSize, 2.5, ippBorderRepl, ipp32f, 1, pSpec, pBuffer);

	ippiFilterGaussianBorder_32f_C1R(imagetoalign.data(), vis[0]->imageWidth * sizeof(Ipp32f), gaussblurred.data(), vis[0]->imageWidth * sizeof(Ipp32f), roiSize, ippBorderRepl, pSpec, pBuffer);
	imagetoalign = gaussblurred;



	//END CREATING INITIAL MEAN

	//START SECONDARY MEAN

	cout << "Creating secondary Mean " << endl;

	for (int loopcount = 0; loopcount < iterations; loopcount++) {
		cout << "Iteration " << loopcount + 1 << endl;
		std::fill(alignedimage.begin(), alignedimage.end(), 0.0);
		for (int imcount = 0; imcount < vis[0]->numOfFrames; imcount++) {

			for (int chancount = 0; chancount < numInputFiles; chancount++) 
				if (chancount == 0)vis[0]->read1dImage(imcount, combimage);
				else {
					vis[chancount]->read1dImage(imcount, imagein);
					transformclass.transform(imagein, imaget, angle[chancount-1] * 3.14159 / 180.0, scale[chancount-1], -xoffset[chancount-1], -yoffset[chancount-1]);
					ippsAdd_32f_I(imaget.data(), combimage.data(), vis[0]->imagePoints);
				}

			if (loopcount<iterations - 1)alignclass.imageAligntopixel(imagetoalign, combimage);
			else alignclass.imageAlign(imagetoalign, combimage);

			transformclass.imageTranslate(combimage, imaget, -alignclass.offsetx, -alignclass.offsety);
			ippsAdd_32f_I(imaget.data(), alignedimage.data(), vis[0]->imagePoints);


			driftsout[imcount][0] = alignclass.offsetx;
			driftsout[imcount][1] = alignclass.offsety;
		}
		ippsDivC_32f_I((Ipp32f)vis[0]->numOfFrames*numInputFiles, alignedimage.data(), vis[0]->imagePoints);


		imagetoalign = alignedimage;

		ippiFilterGaussianBorder_32f_C1R(imagetoalign.data(), vis[0]->imageWidth * sizeof(Ipp32f), gaussblurred.data(), vis[0]->imageWidth * sizeof(Ipp32f), roiSize, ippBorderRepl, pSpec, pBuffer);
		imagetoalign = gaussblurred;



	}



	//Making final Images
	for (int chancount = 0; chancount < numInputFiles; chancount++)
		for (int imcount = 0; imcount < vis[0]->numOfFrames; imcount++) {
			if (chancount == 0) {
				vis[0]->read1dImage(imcount, imagein);
				transformclass.imageTranslate(imagein, imaget, -driftsout[imcount][0], -driftsout[imcount][1]);
			}	else {
				vis[chancount]->read1dImage(imcount, imagein);
				transformclass.transform(imagein, imaget, angle[chancount-1] * 3.14159 / 180.0, scale[chancount-1], -xoffset[chancount-1] - driftsout[imcount][0], -yoffset[chancount-1] - driftsout[imcount][1]);
			}
			ippsAdd_32f_I(imaget.data(), finalmeanimage[chancount].data(), vis[0]->imagePoints);
	}

	for (int i = 0; i < numInputFiles; i++) ippsDivC_32f_I((Ipp32f)vis[0]->numOfFrames, finalmeanimage[i].data(), vis[0]->imagePoints);

}