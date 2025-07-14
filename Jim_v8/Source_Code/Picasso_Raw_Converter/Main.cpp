#include <string>
#include <iostream>
#include <vector>
#include "BLTiffIO.h"
#include "BLCSVIO.h"

using namespace std;

int main(int argc, char* argv[])
{

	string fileIn, outputName;

	try {
		if (argc < 3)throw std::invalid_argument("Insufficient Arguments");
		fileIn = std::string(argv[1]);
		outputName = std::string(argv[2]);
	}
	catch (const std::invalid_argument & e) {
		std::cout << "Error Inputting Parameters\n";
		std::cout << e.what() << "\n";
		std::cout << "See -Help for help\n";
		return 1;
	}

	cout << "test " << fileIn << "\n test2 " << outputName << "\n";

	BLTiffIO::TiffInput im(fileIn);

	std::ofstream myfile;

	string yamlFileName = outputName + ".yaml";
	cout << "Writing out file: " << yamlFileName << "\n";
	string outputstring;
	myfile.open(yamlFileName.c_str());
	outputstring = "Frames: " + std::to_string(im.numOfFrames) + "\nData Type: uint16\nByte Order: <\nHeight: " + std::to_string(im.imageHeight) + "\nWidth: " + std::to_string(im.imageWidth) + "\n";
	myfile << outputstring;
	myfile.close();

	vector<uint16_t> outputIm;

	
	ofstream ofs;
	string rawFileName = outputName + ".raw";

	cout << "Writing out file: " << rawFileName << "\n";

	ofs.open(rawFileName, std::ofstream::binary | std::ofstream::out | std::ofstream::trunc);
	for (uint32_t j = 0; j < im.numOfFrames; j++) {
		im.read1dImage(j, outputIm);
		for (uint32_t i = 0; i < im.imagePoints; i++)ofs.write((char*)&outputIm[i], 2);
	}
	ofs.close();
	
	return 0;
}