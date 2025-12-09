#include "BLTiffIO.h"
#include "BLImageTransform.h"
#include "writeChannelAlignment.hpp"
#include <stdexcept> 

void driftCorrect(std::vector<BLTiffIO::TiffInput*> is, const std::vector< std::vector<float>>& alignment, std::vector< std::vector<float>>& drifts, const float& maxShift, std::vector<float>& referenceImage, std::vector<std::vector<float>>& outputImage, const std::string& alignedStackNameBase);
std::vector< std::vector<float>> findAlignment(std::vector< std::vector<float>>& prealignmentReference, uint32_t imageWidth, uint32_t imageHeight, float maxShift);

int Align_Channels(std::string fileBase, std::vector<std::string>& inputfiles, int startFrame, int endFrame, std::vector<std::vector<float>>& alignments, bool skipIndependentDrifts, float maxShift, bool outputAligned)
{

	//Aim only open each file twice (thrice if auto alignment)
	//once to make sub average, once to align everything
	//also removing initial full stack as it requires a full read
	std::vector<BLTiffIO::TiffInput*> is(inputfiles.size());
	for (int i = 0; i < inputfiles.size(); i++)is[i] = new BLTiffIO::TiffInput(inputfiles[i]);


	const uint32_t imageWidth = is[0]->imageWidth;
	const uint32_t imageHeight = is[0]->imageHeight;
	const uint64_t imagePoints = imageWidth * imageHeight;
	const uint64_t numOfFrames = is[0]->numOfFrames;
	const uint64_t numOfChan = is.size();

	std::vector<float> imagein(imagePoints, 0), imagetoalign(imagePoints, 0), outputImage(imagePoints, 0);
	std::vector< std::vector<float> > prealignmentReference(numOfChan, std::vector<float>(imagePoints, 0)), imageOut(numOfChan, std::vector<float>(imagePoints, 0));
	imageTransform_32f transformclass(imageWidth, imageHeight);

	//make output image files
	std::string filenameOut = fileBase + "_Reference_Frames_Before.tiff";
	BLTiffIO::TiffOutput BeforePartial(filenameOut, imageWidth, imageHeight, 16);

	std::vector<std::vector<float>> drifts;

	//make initial stack for alignment
	std::cout << "Creating Initial Mean " << "\n";
	for (int chancount = 0; chancount < numOfChan; chancount++) {
		for (int imcount = startFrame; imcount < endFrame; imcount++) {//sum frames for each channel
			is[chancount]->read1dImage(imcount, imagein);
			std::transform(prealignmentReference[chancount].begin(), prealignmentReference[chancount].end(), imagein.begin(), prealignmentReference[chancount].begin(), std::plus<float>());
		}
		float divisor = (float)(endFrame - startFrame + 1);
		std::transform(prealignmentReference[chancount].begin(), prealignmentReference[chancount].end(), prealignmentReference[chancount].begin(), [divisor](float val) { return val / divisor; });
		BeforePartial.write1dImage(prealignmentReference[chancount]);
	}

	//calculate channel alignment if not supplied
	if (alignments.size()==0 && numOfChan > 1) {
		//use aligned full stack for reference if specified
		if (skipIndependentDrifts == false) {
			for (int chancount = 0; chancount < numOfChan; chancount++) {
				driftCorrect({ is[chancount] }, alignments, drifts, maxShift, prealignmentReference[chancount], imageOut, "");
				prealignmentReference[chancount] = imageOut[0];
			}
		}

		alignments = findAlignment(prealignmentReference, imageWidth, imageHeight, maxShift);

	}
	//end calculating channel alignment

	//make reference image by transforming and summing my partial reference images

	imagetoalign = prealignmentReference[0];
	for (int chancount = 1; chancount < numOfChan; chancount++) {
		//add align to mean aligned image for each channel
		transformclass.transform(prealignmentReference[chancount], imagein, -alignments[chancount - 1][0], -alignments[chancount - 1][1], alignments[chancount - 1][2], alignments[chancount - 1][3]);
		std::transform(imagetoalign.begin(), imagetoalign.end(), imagein.begin(), imagetoalign.begin(), std::plus<float>());
	}


	//string to save output stack if required
	std::string outputAlignedString = "";
	if (outputAligned)outputAlignedString = fileBase;

	//drift correct stack
	driftCorrect(is, alignments, drifts, maxShift, imagetoalign, imageOut, outputAlignedString);

	//output results

	writeChannelAlignment(fileBase, alignments, imageWidth, imageHeight);
	writeDrifts(fileBase, drifts, alignments, imageWidth, imageHeight);

	//write out aligned full stack images
	filenameOut = fileBase + "_Full_Projection_After.tiff";
	BLTiffIO::TiffOutput AfterFull(filenameOut, imageWidth, imageHeight, 16);
	for (int chancount = 0; chancount < numOfChan; chancount++)BeforePartial.write1dImage(imageOut[chancount]);

	for (auto ptr : is) delete ptr;

	return 0;
}