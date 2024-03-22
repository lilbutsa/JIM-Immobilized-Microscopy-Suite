#include "myHeader.hpp"


void driftCorrect(vector<BLTiffIO::TiffInput*> is, vector< vector<float>> alignment, uint32_t start, uint32_t end, uint32_t iterations, uint32_t maxShift, string fileBase, bool bOutputStack, vector<float>& outputImage,std::string driftFileName){

	const uint32_t imageWidth = is[0]->imageWidth;
	const uint32_t imageHeight = is[0]->imageHeight;
	const uint32_t imagePoints = imageWidth*imageHeight;
	const uint32_t numOfFrames = is[0]->numOfFrames;
	const uint32_t numOfChan = is.size();

	vector<float> imagein(imagePoints, 0), imaget(imagePoints, 0), imagetoalign(imagePoints, 0);
	vector< vector<float> > alignedImages(numOfChan, vector<float>(imagePoints, 0));

	outputImage.resize(imagePoints);

	vector< vector<float> > driftsout(numOfFrames, vector<float>(2, 0.0));

	alignImages_32f alignclass(10, imageWidth, imageHeight);
	imageTransform_32f transformclass(imageWidth, imageHeight);

	std::cout << "Creating Initial Mean " << endl;
	for (int chancount = 0; chancount < numOfChan; chancount++){
		for (int imcount = 0; imcount < numOfFrames; imcount++) {
			is[chancount]->read1dImage(imcount, imagein);
			if (imcount >= start && imcount < end)ippsAdd_32f_I(imagein.data(), imaget.data(), is[0]->imagePoints);

		}
		ippsDivC_32f_I((Ipp32f)(end - start + 1), imaget.data(), is[0]->imagePoints);

		if (chancount > 0){
			transformclass.transform(imaget, imagein, alignment[chancount - 1][2] * 3.14159 / 180.0, alignment[chancount - 1][3], -alignment[chancount - 1][0], -alignment[chancount - 1][1]);
			imaget = imagein;
		}

		ippsAdd_32f_I(imaget.data(), imagetoalign.data(), imagePoints);
	}
	ippsDivC_32f_I((Ipp32f)(is.size()), imagetoalign.data(), imagePoints);


	vector<float> gaussblurred(imagePoints, 0);

	IppiSize roiSize = { (int)imageWidth, (int)imageHeight };
	Ipp32u kernelSize = 5;
	int iTmpBufSize = 0, iSpecSize = 0;
	ippiFilterGaussianGetBufferSize(roiSize, kernelSize, ipp32f, 1, &iSpecSize, &iTmpBufSize);
	IppFilterGaussianSpec* pSpec = (IppFilterGaussianSpec *)ippsMalloc_8u(iSpecSize);
	Ipp8u* pBuffer = ippsMalloc_8u(iTmpBufSize);
	ippiFilterGaussianInit(roiSize, kernelSize, 2.5, ippBorderRepl, ipp32f, 1, pSpec, pBuffer);

	ippiFilterGaussianBorder_32f_C1R(imagetoalign.data(), imageWidth * sizeof(Ipp32f), gaussblurred.data(), imageWidth * sizeof(Ipp32f), roiSize, ippBorderRepl, pSpec, pBuffer);
	imagetoalign = gaussblurred;

	//END CREATING INITIAL MEAN
	vector<float> combimage(imagePoints, 0.0);

	cout << "Creating secondary Mean " << endl;


	for (int loopcount = 0; loopcount < iterations; loopcount++) {
		//cout << "Iteration " << loopcount + 1 << endl;
		std::fill(outputImage.begin(), outputImage.end(), 0.0);
			for (int imcount = 0; imcount < numOfFrames; imcount++) {
				
				for (int chancount = 0; chancount < numOfChan; chancount++) {
					if(chancount==0)is[0]->read1dImage(imcount, combimage);
					else {
						is[chancount]->read1dImage(imcount, imagein);
						transformclass.transform(imagein, imaget, alignment[chancount - 1][2] * 3.14159 / 180.0, alignment[chancount - 1][3], -alignment[chancount - 1][0], -alignment[chancount - 1][1]);
						ippsAdd_32f_I(imaget.data(), combimage.data(), is[0]->imagePoints);
					}	
				}
				
				if (loopcount < iterations - 1)alignclass.imageAligntopixel(imagetoalign, combimage, maxShift);
				else alignclass.imageAlign(imagetoalign, combimage, maxShift);

				driftsout[imcount][0] = alignclass.offsetx;
				driftsout[imcount][1] = alignclass.offsety;

				transformclass.imageTranslate(combimage, imaget, -alignclass.offsetx, -alignclass.offsety);
				ippsAdd_32f_I(imaget.data(), outputImage.data(), is[0]->imagePoints);

			}
			ippsDivC_32f_I((Ipp32f)numOfFrames*numOfChan, outputImage.data(), imagePoints);
			//cout << endl;

			imagetoalign= outputImage;
			//ippiFilterGaussianBorder_32f_C1R(imagetoalign.data(), is[0]->imageWidth * sizeof(Ipp32f), gaussblurred.data(), is[0]->imageWidth * sizeof(Ipp32f), roiSize, ippBorderRepl, pSpec, pBuffer);
			//imagetoalign = gaussblurred;

	}

	vector<float> vBeforeP(imagePoints, 0);
	vector<float> vBeforeF(imagePoints, 0);
	vector<float> vAfterP(imagePoints, 0);
	vector<float> vAfterF(imagePoints, 0);
	std::string filenameOut;
	
	BLTiffIO::TiffOutput* outputstack = NULL;
	

	if (fileBase.empty() == false) {



		filenameOut = fileBase + "_Reference_Frames_Before.tiff";
		BLTiffIO::TiffOutput BeforePartial(filenameOut, imageWidth, imageHeight, 16);

		filenameOut = fileBase + "_Full_Projection_Before.tiff";
		BLTiffIO::TiffOutput BeforeFull(filenameOut, imageWidth, imageHeight, 16);

		filenameOut = fileBase + "_Reference_Frames_After.tiff";
		BLTiffIO::TiffOutput AfterPartial(filenameOut, imageWidth, imageHeight, 16);

		filenameOut = fileBase + "_Full_Projection_After.tiff";
		BLTiffIO::TiffOutput AfterFull(filenameOut, imageWidth, imageHeight, 16);



		for (int chancount = 0; chancount < numOfChan; chancount++) {
			std::fill(vAfterP.begin(), vAfterP.end(), 0.0);
			std::fill(vAfterF.begin(), vAfterF.end(), 0.0);
			std::fill(vBeforeP.begin(), vBeforeP.end(), 0.0);
			std::fill(vBeforeF.begin(), vBeforeF.end(), 0.0);

			if (bOutputStack) {
				filenameOut = fileBase + "_Channel_"+ to_string(chancount + 1)+"_Aligned_Stack.tiff";
				outputstack = new BLTiffIO::TiffOutput(filenameOut, imageWidth, imageHeight, 16);
			}
			
			for (int imcount = 0; imcount < numOfFrames; imcount++) {

				is[chancount]->read1dImage(imcount, imagein);

				if (imcount >= start && imcount < end)ippsAdd_32f_I(imagein.data(), vBeforeP.data(), is[0]->imagePoints);
				ippsAdd_32f_I(imagein.data(), vBeforeF.data(), is[0]->imagePoints);

				if (chancount > 0) {
					transformclass.transform(imagein, imaget, alignment[chancount - 1][2] * 3.14159 / 180.0, alignment[chancount - 1][3], -alignment[chancount - 1][0], -alignment[chancount - 1][1]);
					imagein = imaget;
				}
				//std::cout << "dc imcount = " << imcount << " dx = " << -driftsout[imcount][0] << " dy = " << -driftsout[imcount][1] << "\n";
				transformclass.imageTranslate(imagein, imaget, -driftsout[imcount][0], -driftsout[imcount][1]);

				ippsAdd_32f_I(imaget.data(), vAfterF.data(), is[0]->imagePoints);
				if(imcount>=start && imcount<end)ippsAdd_32f_I(imaget.data(), vAfterP.data(), is[0]->imagePoints);

				if (outputstack!=NULL && bOutputStack)outputstack->write1dImage(imaget);

			}


				ippsDivC_32f_I((Ipp32f)numOfFrames, vBeforeF.data(), imagePoints);
				BeforeFull.write1dImage(vBeforeF);

				ippsDivC_32f_I((Ipp32f)(Ipp32f)(end - start + 1), vBeforeP.data(), imagePoints);
				BeforePartial.write1dImage(vBeforeP);

				ippsDivC_32f_I((Ipp32f)numOfFrames, vAfterF.data(), imagePoints);
				AfterFull.write1dImage(vAfterF);

				ippsDivC_32f_I((Ipp32f)(Ipp32f)(end - start + 1), vAfterP.data(), imagePoints);
				AfterPartial.write1dImage(vAfterP);

				if (outputstack != NULL && bOutputStack)delete outputstack;
		}

	}
	
	if (driftFileName.empty() == false) {
		std::string myFileName = driftFileName + "_Channel_1.csv";
		BLCSVIO::writeCSV(myFileName, driftsout, "X Drift, Y Drift\n");

		for (int chancount = 0; chancount < alignment.size(); chancount++) {
			float x1 = cos(alignment[chancount][2] * 3.14159 / 180.0) / alignment[chancount][3];
			float y1 = -sin(alignment[chancount][2] * 3.14159 / 180.0) / alignment[chancount][3];
			float x2= sin(alignment[chancount][2] * 3.14159 / 180.0) / alignment[chancount][3];
			float y2 = cos(alignment[chancount][2] * 3.14159 / 180.0) / alignment[chancount][3];
			//std::cout << "transform = " << chancount << " " << x1 << " " <<y1 << " " << x2 << " " << y2 << "\n";

			vector<vector<float>> transformedDrifts = driftsout;
			for (int pos = 0; pos < transformedDrifts.size(); pos++) {
				float xin = transformedDrifts[pos][0];
				float yin = transformedDrifts[pos][1];

				transformedDrifts[pos][0] = xin * x1 + yin * y1;
				transformedDrifts[pos][1] = xin * x2 + yin * y2;

			}

			myFileName = driftFileName + "_Channel_" + to_string(chancount+2)+".csv";
			BLCSVIO::writeCSV(myFileName, transformedDrifts, "X Drift, Y Drift\n");
		}
	}

}