#include "myHeader.hpp"


int main(int argc, char *argv[])
{

	if (argc < 2) { std::cout << "could not read files" << endl; return 1; }
	string outputfile = argv[1];

	int numInputFiles = 0;
	vector<string> inputfiles;
	int iterations = 2;

	for (int i = 2; i < argc && std::string(argv[i]) != "-Alignment" && std::string(argv[i]) != "-Start"&& std::string(argv[i]) != "-End"&& std::string(argv[i]) != "-Iterations" && std::string(argv[i]) != "-MaxShift" && std::string(argv[i]) != "-MaxIntensities" && std::string(argv[i]) != "-OutputAligned" && std::string(argv[i]) != "-SNRCutoff"; i++) { numInputFiles++; inputfiles.push_back(argv[i]);}

	bool inputalignment = false;
	int start=0,end=1000000000;
	vector<float> vxoffset, vyoffset, vangle, vscale;

	float maxShift = 1000000;
	vector<float> maxIntensities(numInputFiles, 1000000000000000000.0);

	double SNRCutoff = 1.05;

	bool outputAligned = false;

	for (int i = 1; i < argc; i++) {
		if (std::string(argv[i]) == "-Alignment") {
			inputalignment = true;
			for (int j = 0; j < numInputFiles - 1; j++) {
				if (i + 4 * j < argc) {
					vxoffset.push_back(stod(argv[i + (4 * j) + 1]));
					vyoffset.push_back(stod(argv[i + (4 * j) + 2]));
					vangle.push_back(stod(argv[i + (4 * j) + 3]));
					vscale.push_back(stod(argv[i + (4 * j) + 4]));
					std::cout << "Alignment for Channel " << j + 2 << " xoffset set to  " << vxoffset[j] << " yoffset set to  " << vyoffset[j] << " rotation set to  " << vangle[j] << " scale set to  " << vscale[j] << "\n";
				}
				else { std::cout << "error inputting alignment" << std::endl; return 1; }
			}
		}
		if (std::string(argv[i]) == "-Start") {
			if (i + 1 < argc) {
				start = stoi(argv[i + 1]) - 1;
				start = max(start, 0);
				std::cout << "Calculating initial mean starting from " << start + 1 << endl;
			}
			else { std::cout << "error inputting start" << std::endl; return 1; }
		}
		if (std::string(argv[i]) == "-End") {
			if (i + 1 < argc) {
				end = stoi(argv[i + 1]);
				std::cout << "Calculating initial mean up to frame " << end << endl;
			}
			else { std::cout << "error inputting end" << std::endl; return 1; }
		}
		if (std::string(argv[i]) == "-Iterations") {
			if (i + 1 < argc) {
				iterations = stoi(argv[i + 1]);
				std::cout << "Running alignments with " <<iterations<<" iterations\n";
			}
			else { std::cout << "error inputting end" << std::endl; return 1; }
		}
		if (std::string(argv[i]) == "-MaxShift") {
			if (i + 1 < argc) {
				maxShift = stod(argv[i + 1]);
				std::cout << "Max Shift = " << maxShift << " \n";
			}
			else { std::cout << "error inputting end" << std::endl; return 1; }
		}
		if (std::string(argv[i]) == "-MaxIntensities") {
			for (int j = 0; j < numInputFiles; j++) {
				if (i + 1 + j < argc) {
					maxIntensities[j] = stod(argv[i + 1 + j]);
					std::cout << "Max Intensity for channel " <<j+1<<" = "<< maxIntensities[j] << " \n";
				}
				else { std::cout << "error inputting max intensities" << std::endl; return 1; }
			}
		}
		if (std::string(argv[i]) == "-SNRCutoff") {
			if (i + 1 < argc) {
				SNRCutoff = stod(argv[i + 1]);
				std::cout << "Alignment SNR Cutoff = " << SNRCutoff << " \n";
			}
			else { std::cout << "error inputting SNR cutoff" << std::endl; return 1; }
		}
		if (std::string(argv[i]) == "-OutputAligned") {
			std::cout << "Outputting Aligned Image Stacks\n";
			outputAligned = true;
		}
	}


	
	vector< vector<float> > drifts;
	string adjustedOutputFilename;
	int imageWidth;

	vector< BLTiffIO::TiffOutput*> outputFiles;
	if (outputAligned) {
		BLTiffIO::TiffInput is(inputfiles[0]);
		outputFiles.resize(numInputFiles);
		for (int i = 0; i < numInputFiles; i++) {
			adjustedOutputFilename = outputfile + "_Channel_" + to_string(i + 1) +".tiff";
			outputFiles[i] = new BLTiffIO::TiffOutput(adjustedOutputFilename, is.imageWidth, is.imagePoints / is.imageWidth, 16);
		}
	}

	if (numInputFiles == 1) {
		vector<float> initialmeanimage, finalmeanimage;
		driftCorrectSingleChannel(inputfiles[0], start, end, iterations, initialmeanimage, finalmeanimage, drifts,imageWidth,maxShift, outputFiles);

		adjustedOutputFilename = outputfile + "_initial_partial_mean_1.tiff";
		BLTiffIO::TiffOutput(adjustedOutputFilename, imageWidth,(uint32_t) initialmeanimage.size() / imageWidth, 16).write1dImage(initialmeanimage);

		adjustedOutputFilename = outputfile + "_aligned_full_mean_1.tiff";
		BLTiffIO::TiffOutput(adjustedOutputFilename, imageWidth, (uint32_t)initialmeanimage.size() / imageWidth, 16).write1dImage(finalmeanimage);

		BLCSVIO::writeCSV(outputfile + "_Drifts.csv", drifts, "X Drift, Y Drift\n");
	}
	else if (inputalignment) {
		vector< vector<float> > vinitialmeanimage,vfinalmeanimage;

		driftCorrectMultiChannel(inputfiles, start, end, iterations, vangle, vscale, vxoffset, vyoffset, vinitialmeanimage, vfinalmeanimage, drifts, imageWidth,maxShift, outputFiles);

		for (int i = 0; i < numInputFiles; i++) {
			adjustedOutputFilename = outputfile + "_aligned_partial_mean_" + to_string(i + 1) + ".tiff";
			BLTiffIO::TiffOutput(adjustedOutputFilename, imageWidth, (uint32_t)vfinalmeanimage[0].size() / imageWidth, 16).write1dImage(vinitialmeanimage[i]);

			adjustedOutputFilename = outputfile + "_aligned_full_mean_" + to_string(i + 1) + ".tiff";
			BLTiffIO::TiffOutput(adjustedOutputFilename, imageWidth, (uint32_t)vfinalmeanimage[0].size() / imageWidth, 16).write1dImage(vfinalmeanimage[i]);
		}
		writeChannelAlignment(outputfile, vangle, vscale, vxoffset, vyoffset, imageWidth, vfinalmeanimage[0].size() / imageWidth);
	}
	else alignMultiChannel(inputfiles, start, end, iterations, outputfile, drifts, imageWidth,maxShift,maxIntensities,SNRCutoff, outputFiles);
		

	//Write out drifts
	BLCSVIO::writeCSV(outputfile + "_Drifts.csv", drifts, "X Drift, Y Drift\n");


	//system("PAUSE");
	return 0;



}