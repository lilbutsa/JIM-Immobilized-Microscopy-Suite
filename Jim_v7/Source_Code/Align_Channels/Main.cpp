#include "myHeader.hpp"
#include <stdexcept> 


int main(int argc, char *argv[])
{


	if (argc == 1 || (std::string(argv[1]).substr(0, 2) == "-h" || std::string(argv[1]).substr(0, 2) == "-H")) {
		cout << "Standard input: [Output File Base] [Input Image Stack Channel 1]... Options\n";
		cout << "Options:\n";
		cout << "-Start i (Default i = 1) Specify frame i initially align from\n";
		cout << "-End i (Default i = total number of frames) Specify frame i to initially align to\n";
		cout << "-Iterations i (Default i = 1) Specify the number of alignment iterations to run\n";
		cout << "-MaxShift i (Default i = unlimited) The maximum amount of drift in x and y that will be searched for during alignment\n";
		cout << "-MaxIntensities i j ... to number of channels (Default i = unlimited) Pixels over this intensity are ignored during alignment\n";
		cout << "-SNRCutoff i (Default i = 0.2) SNR of alignment below which an alignment error is thrown\n";
		cout << "-OutputAligned (Default false) Save the aligned imade stacks\n";
		cout << "-SkipIndependentDrifts (Default false) Only Generate combined drifts, For Channel to Channel alignment use the reference frames\n";
		cout << "-Alignment Manually input the alignment between channels. Requires 4 values per extra channel (x offset ch2, ch2... yoffset ch2 ch3..., rotation ch2 ch3... scale ch2 ch3...)\n";
		return 0;
	}


	string fileBase;
	int numInputFiles = 0;
	vector<BLTiffIO::TiffInput*> vcinput;
	bool inputalignment = false,skipIndependentDrifts = false;
	uint32_t iterations = 2,start = 0, end = 1000000000;
	vector<float> maxIntensities;
	vector<vector<float>> alignments;
	float maxShift = 1000000, SNRCutoff = 0.2;
	bool outputAligned = false;


	try {
		if (argc < 3)throw std::invalid_argument("Insufficient Arguments");
		fileBase = std::string(argv[1]);

		for (int i = 2; i < argc && std::string(argv[i]).substr(0, 1) != "-"; i++) numInputFiles++;
		if (numInputFiles == 0)throw std::invalid_argument("No Input Image Stacks Detected");

		vector<string> inputfiles(numInputFiles);
		for (int i = 0; i < numInputFiles; i++)inputfiles[i] = argv[i + 2];
		vcinput.resize(numInputFiles);
		for (int i = 0; i < numInputFiles; i++) {
			vcinput[i] = new BLTiffIO::TiffInput(inputfiles[i]);
		}

		alignments = vector<vector<float>>(numInputFiles-1, {0,0,0,1});
		maxIntensities = vector<float>(numInputFiles, 1000000000000);

		for (int i = 1; i < argc; i++) {
			if (std::string(argv[i]) == "-Iterations") {
				if (i + 1 >= argc)throw std::invalid_argument("No Iterations Input Value");
				try { iterations = stoi(argv[i + 1]); }
				catch (const std::invalid_argument & e) { throw std::invalid_argument("Invalid Iterations Number\nInput :" + std::string(argv[i + 1]) + "\n"); }
				std::cout << "Running alignments with " << iterations << " iterations\n";
			}
			if (std::string(argv[i]) == "-Start") {
				if (i + 1 >= argc)throw std::invalid_argument("No Start Input Value");
				try { start = stoi(argv[i + 1]) - 1; }
				catch (const std::invalid_argument & e) { throw std::invalid_argument("Invalid Start Value\nInput :" + std::string(argv[i + 1]) + "\n"); }
				start = max(start, (uint32_t) 0);
				cout << "Isolating the particle starting from frame " << start + 1 << endl;
			}
			if (std::string(argv[i]) == "-End") {
				if (i + 1 >= argc)throw std::invalid_argument("No End Input Value");
				try { end = stoi(argv[i + 1]); }
				catch (const std::invalid_argument & e) { throw std::invalid_argument("Invalid End Value\nInput :" + std::string(argv[i + 1]) + "\n"); }
				end = min(end, vcinput[0]->numOfFrames);
				cout << "Isolating the particle up to frame " << end << endl;
			}
			if (std::string(argv[i]) == "-MaxShift") {
				if (i + 1 >= argc)throw std::invalid_argument("No Delta Input Value");
				try { maxShift = stoi(argv[i + 1]); }
				catch (const std::invalid_argument & e) { throw std::invalid_argument("Invalid Max Shift Value\nInput :" + std::string(argv[i + 1]) + "\n"); }
				std::cout << "Max Shift = " << maxShift << " \n";
			}
			if (std::string(argv[i]) == "-SNRCutoff") {
				if (i + 1 >= argc)throw std::invalid_argument("No Avergaing Input Value");
				try {SNRCutoff = stod(argv[i + 1]);}
				catch (const std::invalid_argument & e) { throw std::invalid_argument("Invalid Averaging Value\nInput :" + std::string(argv[i + 1]) + "\n"); }
				std::cout << "Alignment SNR Cutoff = " << SNRCutoff << " \n";
			}
			if (std::string(argv[i]) == "-OutputAligned") {
				std::cout << "Outputting Aligned Image Stacks\n";
				outputAligned = true;
			}
			if (std::string(argv[i]) == "-SkipIndependentDrifts") {
				std::cout << "Skipping Calculating Independent Drifts\n";
				skipIndependentDrifts = true;
			}
			if (std::string(argv[i]) == "-Alignment") {
				inputalignment = true;

				std::vector<double> alignmentArguments;
				std::string delimiter = " ";
				for (int j = i + 1; j < argc && std::string(argv[j]).substr(0, 1) != "-"; j++) {
					size_t pos = 0;
					std::string inputStr = argv[j];

					while ((pos = inputStr.find(delimiter)) != std::string::npos) {
						alignmentArguments.push_back(stod(inputStr.substr(0, pos)));
						inputStr.erase(0, pos + delimiter.length());
					}
					alignmentArguments.push_back(stod(inputStr));
				}

				if (alignmentArguments.size()<4*(numInputFiles-1))throw std::invalid_argument("Not Enough Alignment Inputs.\nRequires 4 values per extra channel (x offset ch2 ch2... yoffset ch2 ch3..., rotation ch2 ch3... scale ch2 ch3...)\n");
				for (int j = 0; j < 4; j++)for (int k = 0; k < numInputFiles - 1; k++)alignments[k][j] = alignmentArguments[ k + j * (numInputFiles - 1)]; 
			
			}
			if (std::string(argv[i]) == "-MaxIntensities") {

				std::vector<double> maxIntArguments;
				std::string delimiter = " ";
				for (int j = i + 1; j < argc && std::string(argv[j]).substr(0, 1) != "-"; j++) {
					size_t pos = 0;
					std::string inputStr = argv[j];

					while ((pos = inputStr.find(delimiter)) != std::string::npos) {
						maxIntArguments.push_back(stod(inputStr.substr(0, pos)));
						inputStr.erase(0, pos + delimiter.length());
					}
					maxIntArguments.push_back(stod(inputStr));
				}

				if (maxIntArguments.size() < numInputFiles)throw std::invalid_argument("Not Enough Max Intensity Inputs.\nRequires one value per channel\n");
				for (int k = 0; k < numInputFiles; k++)maxIntensities[k] = maxIntArguments[k];

			}
		}
	}
	catch (const std::invalid_argument & e) {
		std::cout << "Error Inputting Parameters\n";
		std::cout << e.what() << "\n";
		std::cout << "See -Help for help\n";
		return 1;
	}

	try {
		if (numInputFiles == 1) {
			vector<float> outputImage, finalmeanimage;
			//std::string outputFilename = fileBase + "_Combined_Drift.csv";
			driftCorrect(vcinput, alignments, start, end, iterations, maxShift, fileBase, outputAligned, outputImage, fileBase);

		}
		else if (inputalignment) {
			vector<float> outputImage, finalmeanimage;
			std::string outputFilename;
			/*if (skipIndependentDrifts == false) {
				for (int i = 1; i < vcinput.size(); i++) {
					outputFilename = fileBase + "_Channel_" + to_string(i + 1) + "_Drift.csv";
					driftCorrect({ vcinput[i] }, { {} }, start, end, iterations, maxShift, "", false, finalmeanimage, outputFilename);
				}
			}*/
			//outputFilename = fileBase + "_Combined_Drift.csv";
			driftCorrect(vcinput, alignments, start, end, iterations, maxShift, fileBase, outputAligned, outputImage, fileBase);

			writeChannelAlignment(fileBase, alignments, vcinput[0]->imageWidth, vcinput[0]->imageHeight);
		}
		else alignMultiChannel(vcinput, start, end, iterations, maxShift, fileBase, outputAligned, maxIntensities, SNRCutoff, skipIndependentDrifts);
	}
	catch (const std::invalid_argument & e) {
		std::cout << "Error During Drift Correction\n";
		std::cout << e.what() << "\n";
		return 2;
	}

	//system("PAUSE");
	return 0;



}