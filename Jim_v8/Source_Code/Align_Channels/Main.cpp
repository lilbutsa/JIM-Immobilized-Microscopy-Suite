#include "BLTiffIO.h"
#include "BLImageTransform.h"
#include "writeChannelAlignment.hpp"
#include "BLFlagParser.h"
#include <stdexcept> 

void driftCorrect(std::vector<BLTiffIO::TiffInput*> is, const std::vector< std::vector<float>>& alignment, std::vector< std::vector<float>>& drifts, const uint32_t& maxShift, std::vector<float>& referenceImage, std::vector<std::vector<float>>& outputImage, const std::string& alignedStackNameBase);
std::vector< std::vector<float>> findAlignment(std::vector< std::vector<float>>& prealignmentReference, uint32_t imageWidth, uint32_t imageHeight, float maxShift);

int main(int argc, char *argv[])
{

	if (argc == 1 || (std::string(argv[1]).substr(0, 2) == "-h" || std::string(argv[1]).substr(0, 2) == "-H")) {
		std::cout << "Standard input: [Output File Base] [Input Image Stack Channel 1]... Options\n";
		std::cout << "Options:\n";
		std::cout << "-Start i (Default i = 1) Specify frame i initially align from\n";
		std::cout << "-End i (Default i = total number of frames) Specify frame i to initially align to\n";
		std::cout << "-MaxShift i (Default i = unlimited) The maximum amount of drift in x and y that will be searched for during alignment\n";
		std::cout << "-OutputAligned (Default false) Save the aligned image stacks\n";
		std::cout << "-SkipIndependentDrifts (Default false) Only Generate combined drifts, For Channel to Channel alignment use the reference frames\n";
		std::cout << "-Alignment Manually input the alignment between channels. Requires 4 values per extra channel (x offset ch2, ch2... yoffset ch2 ch3..., rotation ch2 ch3... scale ch2 ch3...)\n";
		return 0;
	}


	std::string fileBase;
	int numInputFiles = 0;
	std::vector<BLTiffIO::TiffInput*> is;//input stack
	bool inputalignment = false,skipIndependentDrifts = false;
	uint32_t start = 0, end = 1000000000;
	std::vector<std::vector<float>> alignments;
	std::vector<std::vector<float>> drifts;
	float maxShift = FLT_MAX;
	bool outputAligned = false;



	if (argc < 3)throw std::invalid_argument("Insufficient Arguments");
	fileBase = std::string(argv[1]);

	for (int i = 2; i < argc && std::string(argv[i]).substr(0, 1) != "-"; i++) numInputFiles++;
	if (numInputFiles == 0)throw std::invalid_argument("No Input Image Stacks Detected");

	std::vector<std::string> inputfiles(numInputFiles);
	for (int i = 0; i < numInputFiles; i++)inputfiles[i] = argv[i + 2];
	is.resize(numInputFiles);
	for (int i = 0; i < numInputFiles; i++) {
		is[i] = new BLTiffIO::TiffInput(inputfiles[i]);
	}

	alignments = std::vector<std::vector<float>>(numInputFiles-1, {0,0,0,1});
	std::vector<float> alignmentArguments;

	std::vector<std::pair<std::string, uint32_t*>> intFlags = {{"Start", &start},{"End", &end}};
	std::vector<std::pair<std::string, float*>> floatFlags = {{"MaxShift", &maxShift} };
	std::vector<std::pair<std::string, bool*>> boolFlags = { {"OutputAligned", &outputAligned}, {"SkipIndependentDrifts", &skipIndependentDrifts} };
	std::vector<std::pair<std::string, std::vector<float>*>> vecFlags = { {"Alignment", &alignmentArguments} };

	if (BLFlagParser::parseValues(intFlags, argc, argv)) return 1;
	if (BLFlagParser::parseValues(floatFlags, argc, argv)) return 1;
	if (BLFlagParser::parseValues(boolFlags, argc, argv)) return 1;
	if (BLFlagParser::parseValues(vecFlags, argc, argv)) return 1;


	if (alignmentArguments.size()>0 && alignmentArguments.size() < 4 * (numInputFiles - 1))throw std::invalid_argument("Not Enough Alignment Inputs.\nRequires 4 values per extra channel (x offset ch2 ch2... yoffset ch2 ch3..., rotation ch2 ch3... scale ch2 ch3...)\n");
	if (alignmentArguments.size() >= 4 * (numInputFiles - 1)) {
		inputalignment = true;
		for (int j = 0; j < 4; j++)for (int k = 0; k < numInputFiles - 1; k++)alignments[k][j] = alignmentArguments[k + j * (numInputFiles - 1)];
	}


	//Aim only open each file twice (thrice if aut alignment)
	//once to make sub average, once to align everything
	//also removing initial full stack as it requires a full read

	const uint32_t imageWidth = is[0]->imageWidth;
	const uint32_t imageHeight = is[0]->imageHeight;
	const uint32_t imagePoints = imageWidth * imageHeight;
	const uint32_t numOfFrames = is[0]->numOfFrames;
	const uint32_t numOfChan = is.size();

	std::vector<float> imagein(imagePoints, 0), imagetoalign(imagePoints, 0),outputImage(imagePoints, 0);
	std::vector< std::vector<float> > prealignmentReference(numOfChan, std::vector<float>(imagePoints, 0)), imageOut(numOfChan, std::vector<float>(imagePoints, 0));
	imageTransform_32f transformclass(imageWidth, imageHeight);

	//make output image files
	std::string filenameOut = fileBase + "_Reference_Frames_Before.tiff";
	BLTiffIO::TiffOutput BeforePartial(filenameOut, imageWidth, imageHeight, 16);

	//make initial stack for alignment
	std::cout << "Creating Initial Mean " << "\n";
	for (int chancount = 0; chancount < numOfChan; chancount++) {
		for (int imcount = start; imcount < end; imcount++) {//sum frames for each channel
			is[chancount]->read1dImage(imcount, imagein);
			std::transform(prealignmentReference[chancount].begin(), prealignmentReference[chancount].end(), imagein.begin(), prealignmentReference[chancount].begin(), std::plus<float>());
		}
		float divisor = (end - start + 1);
		std::transform(prealignmentReference[chancount].begin(), prealignmentReference[chancount].end(), prealignmentReference[chancount].begin(), [divisor](float val) { return val / divisor; });
		BeforePartial.write1dImage(prealignmentReference[chancount]);
	}

	//calculate channel alignment if not supplied
	if (inputalignment == false && numOfChan>1) {
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
	writeDrifts(fileBase, drifts,alignments, imageWidth, imageHeight);

	//write out aligned full stack images
	filenameOut = fileBase + "_Full_Projection_After.tiff";
	BLTiffIO::TiffOutput AfterFull(filenameOut, imageWidth, imageHeight, 16);
	for (int chancount = 0; chancount < numOfChan; chancount++)BeforePartial.write1dImage(imageOut[chancount]);

	for (auto ptr : is) delete ptr;

	//system("PAUSE");
	return 0;



}