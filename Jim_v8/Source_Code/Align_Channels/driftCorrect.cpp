/**
 * @file driftCorrect.cpp
 * @brief Implements core functions for drift correction and inter-channel alignment.
 *
 *
 * Functions:
 * - driftCorrect:
 *     Applies sub-pixel drift correction across time, optionally writing out
 *     aligned image stacks and computing averaged projections.
 *
 * - findAlignment:
 *     Estimates relative alignment parameters (translation, rotation, scale)
 *     between channel 1 and all other channels using Fourier-based
 *     cross-correlation and iterative parameter optimization.
 *
 * Dependencies:
 *   - BLTiffIO (for TIFF I/O)
 *   - BLImageTransform (for transformation and alignment logic)
 *
 * Author: James Walsh
 * Date: July 2020
 */


#include "BLTiffIO.h"
#include "BLImageTransform.h"

void driftCorrect(BLTiffIO::MultiTiffInput& input,size_t posIn, int chanIn, const std::vector< std::vector<float>>& alignment, std::vector< std::vector<float>>& drifts, const float& maxShift, std::vector<float>& referenceImage, std::vector<std::vector<float>>& outputImage, const std::string & alignedStackNameBase) {
	//get image info
	size_t imageWidth, imageHeight, imageDepth, numOfChan,numOfFrames,numOfZ;
	input.imageInfo(posIn, imageWidth, imageHeight, imageDepth, numOfChan, numOfFrames, numOfZ);
	size_t imagePoints = imageWidth * imageHeight;
	
	std::vector<float> imaget(imagePoints, 0.0), combimage(imagePoints, 0.0);
	std::vector<std::vector<float>> allChans(numOfChan, std::vector<float>(imagePoints, 0.0));
	drifts = std::vector<std::vector<float>>(numOfFrames, std::vector<float>(2, 0.0));
	outputImage = std::vector<std::vector<float>>(numOfChan, std::vector<float>(imagePoints, 0.0));

	bool bigTiff = false;
	if((size_t)2000000000 / imagePoints < numOfFrames)bigTiff = true;


	size_t chanStart = chanIn < 0 ? 0 : chanIn;
	size_t chanEnd = chanIn < 0 ? numOfChan : chanIn+1;

	//aligned stack output if required
	std::vector<BLTiffIO::TiffOutput*>  outputstack;
	if (alignedStackNameBase.empty() == false) {
		for (int chancount = chanStart; chancount < chanEnd; chancount++) {
			std::string filenameOut = alignedStackNameBase + "_Channel_" + std::to_string(chancount + 1) + "_Aligned_Stack.tiff";
			outputstack.push_back(new BLTiffIO::TiffOutput(filenameOut, imageWidth, imageHeight, 16, bigTiff));
		}
	}
	imageTransform_32f transformclass(imageWidth, imageHeight);
	alignImages_32f alignclass(imageWidth, imageHeight);

	alignclass.alignWithLogLoadIm1(referenceImage, maxShift, 5);

	for (int imcount = 0; imcount < numOfFrames; imcount++) {
		//std::cout << " Imcount = " << imcount << "\n";
		//make a combined image of all channels
		for (int chancount = chanStart; chancount < chanEnd; chancount++) {
			if (chancount == chanStart) {
				input.read1dImage(posIn, imcount, chancount, 0, allChans[chancount]);
				combimage = allChans[chancount];
			}
			else {
				input.read1dImage(posIn, imcount, chancount, 0, imaget);
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
		//std::cout << imcount << " " << alignclass.xAlign << " " << alignclass.yAlign << " " << alignclass.quadFitX << " " << alignclass.quadFitY << " " << "\n";

		for (int chancount = chanStart; chancount < chanEnd; chancount++) {
			//add align to mean aligned image for each channel
			transformclass.translate(allChans[chancount], imaget, -drifts[imcount][0], -drifts[imcount][1]);
			std::transform(outputImage[chancount].begin(), outputImage[chancount].end(), imaget.begin(), outputImage[chancount].begin(), std::plus<float>());

			//save aligned stack image if reqired;
			if (alignedStackNameBase.empty() == false) outputstack[chancount]->write1dImage(imaget);
		}

	}

	float divisor = (float)numOfFrames;
	for (int chancount = chanStart; chancount < chanEnd; chancount++)
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

			for (float scale = hmaxscale - 0.1f * deltain; scale <= hmaxscale + 0.10001f * deltain; scale = scale + 0.01f * deltain)for (float angle = hmaxangle - 5.0f * deltain; angle <= hmaxangle + 5.0001f * deltain; angle = angle + 0.5f * deltain) {

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


