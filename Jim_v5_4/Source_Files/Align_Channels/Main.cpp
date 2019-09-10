#include "myHeader.h"


int main(int argc, char *argv[])
{

	if (argc < 2) { std::cout << "could not read files" << endl; return 1; }
	string outputfile = argv[1];

	int numInputFiles = 0;
	vector<string> inputfiles;
	int iterations = 2;

	for (int i = 2; i < argc && std::string(argv[i]) != "-Alignment" && std::string(argv[i]) != "-Start"&& std::string(argv[i]) != "-End"&& std::string(argv[i]) != "-Iterations"; i++) { numInputFiles++; inputfiles.push_back(argv[i]);}

	bool inputalignment = false;
	int start=0,end=1000000000;
	vector<float> vxoffset, vyoffset, vangle, vscale;


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
				//end = min(end, totnumofframes); ADD THIS IN ONCE THE FILE IS OPEN
				std::cout << "Calculating initial mean up to frame " << end << endl;
			}
			else { std::cout << "error inputting end" << std::endl; return 1; }
		}
		if (std::string(argv[i]) == "-Iterations") {
			if (i + 1 < argc) {
				iterations = stoi(argv[i + 1]);
				//end = min(end, totnumofframes); ADD THIS IN ONCE THE FILE IS OPEN
				std::cout << "Running alignments with " <<iterations<<" iterations\n";
			}
			else { std::cout << "error inputting end" << std::endl; return 1; }
		}
	}


	
	vector<vector<float>> drifts;
	string adjustedOutputFilename;
	int imageWidth;


	if (numInputFiles == 1) {
		vector<float> initialmeanimage, finalmeanimage;
		driftCorrectSingleChannel(inputfiles[0], start, end, iterations, initialmeanimage, finalmeanimage, drifts,imageWidth);

		adjustedOutputFilename = outputfile + "_initial_mean.tiff";
		BLTiffIO::TiffOutput(adjustedOutputFilename, imageWidth,(uint32_t) initialmeanimage.size() / imageWidth, 16).write1dImage(initialmeanimage);

		adjustedOutputFilename = outputfile + "_final_mean.tiff";
		BLTiffIO::TiffOutput(adjustedOutputFilename, imageWidth, (uint32_t)initialmeanimage.size() / imageWidth, 16).write1dImage(finalmeanimage);

		BLCSVIO::writeCSV(outputfile + "_Drifts.csv", drifts, "X Drift, Y Drift\n");
	}
	else if (inputalignment) {
		vector<vector<float>> vinitialmeanimage,vfinalmeanimage;
		driftCorrectMultiChannel(inputfiles, start, end, iterations, vangle, vscale, vxoffset, vyoffset, vinitialmeanimage, vfinalmeanimage, drifts, imageWidth);

		for (int i = 0; i < numInputFiles; i++) {
			adjustedOutputFilename = outputfile + "_aligned_partial_mean_" + to_string(i + 1) + ".tiff";
			BLTiffIO::TiffOutput(adjustedOutputFilename, imageWidth, (uint32_t)vfinalmeanimage[0].size() / imageWidth, 16).write1dImage(vinitialmeanimage[i]);

			adjustedOutputFilename = outputfile + "_aligned_full_mean_" + to_string(i + 1) + ".tiff";
			BLTiffIO::TiffOutput(adjustedOutputFilename, imageWidth, (uint32_t)vfinalmeanimage[0].size() / imageWidth, 16).write1dImage(vfinalmeanimage[i]);
		}
		writeChannelAlignment(outputfile, vangle, vscale, vxoffset, vyoffset, imageWidth, vfinalmeanimage[0].size() / imageWidth);
	}
	else alignMultiChannel(inputfiles, start, end, iterations, outputfile, drifts, imageWidth);
		

	//Write out drifts
	BLCSVIO::writeCSV(outputfile + "_Drifts.csv", drifts, "X Drift, Y Drift\n");


	//system("PAUSE");
	return 0;



}