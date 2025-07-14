#include "BLTiffIO.h"
#include "BLImageTransform.h"

void driftCorrect(std::vector<BLTiffIO::TiffInput*> is, const std::vector< std::vector<float>>& alignment, std::vector< std::vector<float>>& drifts, const uint32_t& maxShift, std::vector<float>& referenceImage, std::vector<std::vector<float>>& outputImage, const std::string & alignedStackNameBase) {
	//get image info
	const uint32_t imageWidth = is[0]->imageWidth;
	const uint32_t imageHeight = is[0]->imageHeight;
	const uint32_t imagePoints = imageWidth * imageHeight;
	const uint32_t numOfFrames = is[0]->numOfFrames;
	const uint32_t numOfChan = is.size();
	
	std::vector<float> imaget(imagePoints, 0.0), combimage(imagePoints, 0.0);
	std::vector<std::vector<float>> allChans(numOfChan, std::vector<float>(imagePoints, 0.0));
	drifts = std::vector<std::vector<float>>(numOfFrames, std::vector<float>(2, 0.0));
	outputImage = std::vector<std::vector<float>>(numOfChan, std::vector<float>(imagePoints, 0.0));

	//aligned stack output if required
	std::vector<BLTiffIO::TiffOutput*>  outputstack;
	if (alignedStackNameBase.empty() == false) {
		for (int chancount = 0; chancount < numOfChan; chancount++) {
			std::string filenameOut = alignedStackNameBase + "_Channel_" + std::to_string(chancount + 1) + "_Aligned_Stack.tiff";
			outputstack.push_back(new BLTiffIO::TiffOutput(filenameOut, imageWidth, imageHeight, 16, is[0]->bigtiff));
		}
	}

	imageTransform_32f transformclass(imageWidth, imageHeight);

	alignImages_32f alignclass(imageWidth, imageHeight);
	alignclass.alignWithLogLoadIm1(referenceImage, maxShift, 5);


	for (int imcount = 0; imcount < numOfFrames; imcount++) {
		//make a combined image of all channels
		for (int chancount = 0; chancount < numOfChan; chancount++) {
			if (chancount == 0) {
				is[chancount]->read1dImage(imcount, allChans[0]);
				combimage = allChans[0];
			}
			else {
				is[chancount]->read1dImage(imcount, imaget);
				transformclass.transform(imaget, allChans[chancount], -alignment[chancount - 1][0], -alignment[chancount - 1][1], alignment[chancount - 1][2], alignment[chancount - 1][3]);
				std::transform(combimage.begin(), combimage.end(), allChans[chancount].begin(), combimage.begin(), std::plus<float>());//add transformed image to combined image
			}
		}

		alignclass.alignIm2(combimage);
		alignclass.fitSubPixelQuadratic();

		drifts[imcount][0] = alignclass.quadFitX;
		drifts[imcount][1] = alignclass.quadFitY;
		//drifts[imcount][0] = alignclass.xAlign;
		//drifts[imcount][1] = alignclass.yAlign;

		for (int chancount = 0; chancount < numOfChan; chancount++) {
			//add align to mean aligned image for each channel
			transformclass.translate(allChans[chancount], imaget, -drifts[imcount][0], -drifts[imcount][1]);
			std::transform(outputImage[chancount].begin(), outputImage[chancount].end(), imaget.begin(), outputImage[chancount].begin(), std::plus<float>());

			//save aligned stack image if reqired;
			if (alignedStackNameBase.empty() == false) outputstack[chancount]->write1dImage(imaget);
		}

	}

	float divisor = numOfFrames;
	for (int chancount = 0; chancount < numOfChan; chancount++)
		std::transform(outputImage[chancount].begin(), outputImage[chancount].end(), outputImage[chancount].begin(), [divisor](float val) { return val / divisor; });
	
}

std::vector< std::vector<float>> findAlignment(std::vector< std::vector<float>>& prealignmentReference, uint32_t imageWidth, uint32_t imageHeight, float maxShift) {
	
	const uint32_t imagePoints = imageWidth * imageHeight;
	std::vector<float> imagein(imagePoints, 0);
	//finding alignment
	alignImages_32f alignclass(imageWidth, imageHeight);
	imageTransform_32f transformclass(imageWidth, imageHeight);
	alignclass.alignWithLogLoadIm1(prealignmentReference[0], maxShift, 5);

	size_t numOfChan = prealignmentReference.size() + 1;

	std::vector<std::vector<float>>alignments (numOfChan - 1, { 0,0,0,1 });
	//find alignment for each channel
	for (int chancount = 1; chancount < numOfChan; chancount++) {
		std::cout << "Finding Orientation for Channel " << chancount + 1 << "\n";
		float maxcc = 0;
		float deltain = 4;
		float maxscale = 1;
		float maxangle = 0;
		float xoffset = 0;
		float yoffset = 0;


		for (int delta = 0; delta < 3; delta++) {//delta decreases each iteration to search around the highest CC point
			deltain *= 0.25;
			float hmaxscale = maxscale;
			float hmaxangle = maxangle;

			for (double scale = hmaxscale - 0.1 * deltain; scale <= hmaxscale + 0.10001 * deltain; scale = scale + 0.01 * deltain)for (double angle = hmaxangle - 5.0 * deltain; angle <= hmaxangle + 5.0001 * deltain; angle = angle + 0.5 * deltain) {

				transformclass.transform(prealignmentReference[chancount], imagein, 0, 0, angle, scale);
				alignclass.alignIm2(imagein);


				if (alignclass.maxCCVal > maxcc) {
					maxcc = alignclass.maxCCVal;
					maxangle = angle;
					maxscale = scale;
					alignclass.fitSubPixelQuadratic();
					xoffset = alignclass.quadFitX;
					yoffset = alignclass.quadFitY;

					//std::cout << "maxcc = " << maxcc << " max angle =  " << maxangle << " max scale = " << maxscale << "  x offset = " << xoffset << " y offset = " << yoffset << "\n";
				}
			}
		}

		std::cout << "Fit CC = " << maxcc << "  x offset = " << xoffset << " y offset = " << yoffset << " max angle =  " << maxangle << " max scale = " << maxscale << "\n";

		alignments[chancount - 1][0] = xoffset;
		alignments[chancount - 1][1] = yoffset;
		alignments[chancount - 1][2] = maxangle;
		alignments[chancount - 1][3] = maxscale;
	}
	return alignments;
}
//end calculating channel alignment


