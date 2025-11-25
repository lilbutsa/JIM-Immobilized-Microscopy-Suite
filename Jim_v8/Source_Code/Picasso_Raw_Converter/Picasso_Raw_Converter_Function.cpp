#include <string>
#include <iostream>
#include <vector>
#include "BLTiffIO.h"


int Picasso_Raw_Converter(std::string outputName, std::string fileIn) {
	std::cout << "Input file  :" << fileIn << "\n Output file : : " << outputName << "\n";

	BLTiffIO::TiffInput im(fileIn);

	std::ofstream myfile;

	std::string yamlFileName = outputName + ".yaml";
	std::cout << "Writing out file: " << yamlFileName << "\n";
	std::string outputstring;
	myfile.open(yamlFileName.c_str());
	outputstring = "Frames: " + std::to_string(im.numOfFrames) + "\nData Type: uint16\nByte Order: <\nHeight: " + std::to_string(im.imageHeight) + "\nWidth: " + std::to_string(im.imageWidth) + "\n";
	myfile << outputstring;
	myfile.close();

	std::vector<uint16_t> outputIm;


	std::ofstream ofs;
	std::string rawFileName = outputName + ".raw";

	std::cout << "Writing out file: " << rawFileName << "\n";

	ofs.open(rawFileName, std::ofstream::binary | std::ofstream::out | std::ofstream::trunc);
	for (uint32_t j = 0; j < im.numOfFrames; j++) {
		im.read1dImage(j, outputIm);
		for (uint32_t i = 0; i < im.imagePoints; i++)ofs.write((char*)&outputIm[i], 2);
	}
	ofs.close();


}