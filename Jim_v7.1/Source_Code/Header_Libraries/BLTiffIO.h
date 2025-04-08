#pragma once
#ifndef BLTiffIO_H
#define BLTiffIO_H

#include <stdint.h>
#include <string>
#include <iostream>
#include <fstream>
#include <vector>
#include <stdexcept>


namespace BLTiffIO {

	class TiffInput {

		std::string filename;

		uint8_t input8bit;
		uint16_t input16bit;
		uint32_t input32bit;
		uint64_t input64bit;
		char inputbit[8];

		std::vector<uint8_t> vinput8bit;
		std::vector<uint16_t> vinput16bit;
		std::vector<uint32_t> vinput32bit;

		bool bigendian;

		uint32_t currentoffset;
		uint64_t currentoffset64;

		uint16_t countofifd;
		uint64_t countofifd64;

		std::vector<uint32_t> allfilepositions;

		std::vector<uint64_t> allfilepositions64;

		std::ifstream ifs;

		void read8bitimage();
		void read16bitimage();
		void read32bitimage();


		uint8_t read8bit();
		uint16_t read16bit();
		uint32_t read32bit();
		uint64_t read64bit();
		uint64_t readbit(int bitDepth);

		void ReadIFDTag();
		void ReadBigIFDTag();

		void parseOMEMetadata();

		uint32_t numofstrips, rowsperstrip, stripNumBytes, byteNumBytes;
		uint64_t stripoffset, bytecountoffset;

	public:

		uint64_t filesize;
		uint32_t numOfFrames;
		uint32_t imageWidth;
		uint32_t imageHeight;
		uint32_t imageDepth;
		uint32_t imagePoints;

		std::string OMEmetadata;
		bool OMEmetadataDetected;
		std::vector<std::vector<uint32_t> > imageOrder; //ordered T,C,Z,N
		std::string inputfile;

		bool bigtiff;

		TiffInput(std::string filenamein, bool detectMetadata = true);
		~TiffInput();

		template <typename vectortype>
		void read1dImage(uint16_t framenumber, ::std::vector<vectortype>& imageout);

		template <typename vectortype>
		void read2dImage(uint16_t framenumber, ::std::vector< ::std::vector<vectortype> >& imageout);

	};

	inline uint8_t TiffInput::read8bit() {
		ifs.read((char*)& input8bit, 1);

		return input8bit;
	}

	inline uint16_t TiffInput::read16bit() {
		ifs.read((char*)& input16bit, 2);
		if (bigendian) {
			return (((input16bit >> 8)) | (input16bit << 8));
		}
		return input16bit;
	}

	inline uint32_t TiffInput::read32bit() {
		ifs.read((char*)& input32bit, 4);
		if (bigendian) {
			return (((input32bit & 0x000000FF) << 24) + ((input32bit & 0x0000FF00) << 8) +
				((input32bit & 0x00FF0000) >> 8) + ((input32bit & 0xFF000000) >> 24));
		}
		return input32bit;
	}

	inline uint64_t TiffInput::read64bit()
	{
		ifs.read((char*)&input64bit, 8);
		if (bigendian) {
			return ((input64bit << 56) |
				((input64bit & 0x000000000000FF00) << 40) |
				((input64bit & 0x0000000000FF0000) << 24) |
				((input64bit & 0x00000000FF000000) << 8) |
				((input64bit & 0x000000FF00000000) >> 8) |
				((input64bit & 0x0000FF0000000000) >> 24) |
				((input64bit & 0x00FF000000000000) >> 40) |
				(input64bit >> 56)
				);
		}
		return input64bit;
	}

	inline uint64_t TiffInput::readbit(int dataType)
	{

		int bitDepth;
		if (dataType == 1) bitDepth = 1;
		else if (dataType == 3) bitDepth = 2;
		else if (dataType == 4) bitDepth = 4;
		else bitDepth = 64;

		ifs.read(inputbit, bitDepth);

		input64bit = 0;
		if (bigendian) for (int i = 0; i < bitDepth; i++)input64bit = 256 * input64bit + ((uint8_t)inputbit[i]);
		else for (int i = bitDepth-1; i >-1; i--)input64bit = 256 * input64bit + ((uint8_t)inputbit[i]);

		return input64bit;
	}


	inline void TiffInput::read8bitimage() {
		ifs.read((char*) vinput8bit.data(), imagePoints);
	}

	inline void TiffInput::read16bitimage() {
		
		uint32_t impointx2 = (2 * imagePoints);
		ifs.read((char*)vinput16bit.data(), impointx2);
		if (bigendian) {
			for(uint32_t i=0;i<imagePoints;i++)vinput16bit[i] = (((vinput16bit[i] >> 8)) | (vinput16bit[i] << 8));
		}

	}

	inline void TiffInput::read32bitimage() {
		uint32_t impointx4 = (4 * imagePoints);
		ifs.read((char*)vinput32bit.data(), impointx4);

		if (bigendian) {
			for (uint32_t i = 0; i<imagePoints; i++)vinput32bit[i] = (((vinput32bit[i] & 0x000000FF) << 24) + ((vinput32bit[i] & 0x0000FF00) << 8) +
				((vinput32bit[i] & 0x00FF0000) >> 8) + ((vinput32bit[i] & 0xFF000000) >> 24));
		}

	}


	inline void TiffInput::parseOMEMetadata() {
		imageOrder.clear();

		inputfile = filename;

		const size_t last_slash_idx = inputfile.find_last_of("\\/");
		if (std::string::npos != last_slash_idx)
		{
			inputfile.erase(0, last_slash_idx + 1);
		}

		std::cout << "Attempting to read OME data for " << inputfile << "\n";
		//std::cout << OMEmetadata<<"\n";
		//std::cout << OMEmetadata.substr(0,5000) << "\n";
		std::vector<uint32_t> singleLine(4);
		std::string inputStr = OMEmetadata;
		uint64_t strPos = inputStr.find("<TiffData");
		uint64_t endPos = inputStr.find("</TiffData");
		uint64_t tiffdataLength = endPos - strPos;
		while (strPos != std::string::npos && endPos != std::string::npos) {
			std::string subStr = inputStr.substr(strPos, endPos - strPos);


			std::string subsubstr = subStr.substr(subStr.find("FileName=\"") + 10);
			std::string filenamein = (subsubstr.substr(0, subsubstr.find("\"")));

			if (filename.find(filenamein) != std::string::npos) {


				std::cout << filename << " vs " << filenamein << "\n";

				subsubstr = subStr.substr(subStr.find("FirstT=\"") + 8);
				singleLine[0] = std::stoi(subsubstr.substr(0, subsubstr.find("\"")));

				subsubstr = subStr.substr(subStr.find("FirstC=\"") + 8);
				singleLine[1] = std::stoi(subsubstr.substr(0, subsubstr.find("\"")));

				subsubstr = subStr.substr(subStr.find("FirstZ=\"") + 8);
				singleLine[2] = std::stoi(subsubstr.substr(0, subsubstr.find("\"")));

				subsubstr = subStr.substr(subStr.find("IFD=\"") + 5);
				singleLine[3] = std::stoi(subsubstr.substr(0, subsubstr.find("\"")));

				imageOrder.push_back(singleLine);
			}
			else {
				//std::cout << "other file = " << filename<<"\n";
				//std::cout << "looking for = " << inputfile << "\n";
				endPos = inputStr.find(inputfile);
				if (endPos == std::string::npos) {
					//std::cout << "not found\n";
					break;
				}// else std::cout << "found at = " << endPos << "\n";
				endPos = endPos - tiffdataLength;
				inputStr = inputStr.substr(endPos);
				endPos = inputStr.find("</TiffData");
			}


			//std::cout << singleLine[0] << " " << singleLine[1] << " " << singleLine[2] << " " << singleLine[3] << " "<<inputStr.size()<<"\n";

			inputStr = inputStr.substr(endPos + 10);

			strPos = inputStr.find("<TiffData");
			endPos = inputStr.find("</TiffData");
		}

	}

	inline TiffInput::TiffInput(std::string filenamein,bool detectMetadata) {
		filename = filenamein;

		OMEmetadataDetected = false;

		ifs.open(filename, std::ifstream::ate | std::ifstream::binary);
		if (ifs.is_open() == false) {
			throw std::invalid_argument("Error:could not open file:\n" + filenamein + "\n");
			return;
		}

		filesize = ifs.tellg();
		ifs.close();

		ifs.open(filename, std::ifstream::binary);

		ifs.read((char*)&input16bit, 2);
		if (input16bit == 19789)bigendian = true;
		else if (input16bit == 18761)bigendian = false;
		else std::invalid_argument("Error reading which endian the Image Stack is!\n" + filename + "\n");

		uint16_t bigtiffval = read16bit();
		if (bigtiffval == 42)bigtiff = false;
		else if (bigtiffval == 43)bigtiff = true;
		else {
			std::invalid_argument("Could not determine if Image format is Tiff or Big Tiff!\n" + filename + "\n");
			return;
		}


		if (bigtiff) {
			//std::cout << "Reading big tiff\n";
			read16bit();
			read16bit();
			currentoffset64 = read64bit();
			uint64_t lastoffset64 = 1;
			while (currentoffset64 > 0 && lastoffset64 != currentoffset64) {

				allfilepositions64.push_back(currentoffset64);

				ifs.seekg(currentoffset64);

				countofifd64 = read64bit();

				lastoffset64 = currentoffset64;

				currentoffset64 += 8 + 20 * countofifd64;

				ifs.seekg(currentoffset64);
				currentoffset64 = read64bit();

			}
			numOfFrames = allfilepositions64.size();

			std::cout << "Number of frames = "<< numOfFrames<<"\n";

			ifs.seekg(allfilepositions64[0]);
			countofifd64 = read64bit();
			uint16_t ifdtag, datatype;
			uint64_t outputnum, datanum;
			for (uint16_t i = 0; i < countofifd64; i++) {
				ifdtag = read16bit();
				datatype = read16bit();
				datanum = read64bit();

				if (datatype == 3) {
					outputnum = read16bit();
					read16bit();
					read16bit();
					read16bit();
				}
				else if (datatype == 1) {
					outputnum = read8bit();
					ifs.read((char*)&input64bit, 7);
				}
				else if (datatype >15) {
					outputnum = read64bit();
				}
				else {
					outputnum = read32bit();
					read32bit();
				}

				if (ifdtag == 256)imageWidth = outputnum;
				else if (ifdtag == 257)imageHeight = outputnum;
				else if (ifdtag == 258)imageDepth = outputnum;
				else if (ifdtag == 270) {
					uint64_t currentpos = ifs.tellg();
					ifs.seekg(outputnum);
					std::vector<char>descriptionin(datanum);
					ifs.read(descriptionin.data(), datanum);
					std::string metadata = std::string(descriptionin.data());
					if (metadata.compare(0, 14, "<?xml version=") == 0) {
						
						OMEmetadata = metadata;
						if (OMEmetadataDetected == false && detectMetadata) {
							parseOMEMetadata();
							OMEmetadataDetected = true;
						}
					}

					ifs.seekg(currentpos);
				}
			}


		}
		else {
			//std::cout << "Analysing small tiff\n";
			currentoffset = read32bit();
			uint32_t lastoffset = 1;

			while (currentoffset > 0 && lastoffset!=currentoffset) {
				allfilepositions.push_back(currentoffset);

				ifs.seekg(currentoffset);

				countofifd = read16bit();

				lastoffset = currentoffset;

				currentoffset += 2 + 12 * countofifd;

				ifs.seekg(currentoffset);
				currentoffset = read32bit();

			}

			if (ifs.tellg()==-1) {
				allfilepositions.pop_back();
				ifs.close();
				ifs.open(filename, std::ifstream::binary);
			}



			numOfFrames = allfilepositions.size();

			ifs.seekg(allfilepositions[0]);
			
			countofifd = read16bit();
			uint16_t ifdtag, datatype;
			uint32_t outputnum, datanum;
			for (uint16_t i = 0; i < countofifd; i++) {
				ifdtag = read16bit();
				datatype = read16bit();
				datanum = read32bit();

				if (datatype == 3) {
					outputnum = read16bit();
					read16bit();
				}
				else if (datatype == 1) {
					outputnum = read8bit();
					read8bit();
					read8bit();
					read8bit();
				}
				else outputnum = read32bit();

				if (ifdtag == 256) imageWidth = outputnum;
				else if (ifdtag == 257)imageHeight = outputnum;
				else if (ifdtag == 258)imageDepth = outputnum;
				else if (ifdtag == 270) {
					uint64_t currentpos = ifs.tellg();
					ifs.seekg(outputnum);
					std::string metadata;
					if (datanum > 0) {
						std::vector<char>descriptionin(datanum);
						ifs.read(descriptionin.data(), datanum);
						metadata = std::string(descriptionin.data());
					}
					//std::cout << "all270 tages = " << metadata << "\n";
					//std::cout << "the OME Metadata is " << datanum << " bytes?\n";
					if (metadata.compare(0, 14, "<?xml version=")==0) {
						OMEmetadata = metadata;
						if (OMEmetadataDetected == false && detectMetadata) {
							parseOMEMetadata();
							OMEmetadataDetected = true;
						}
					}

					ifs.seekg(currentpos);
				}

				//std::cout << "small tiff ifd tag " << ifdtag << " data type " << datatype << " number of entries " << datanum << " value " << outputnum << "\n";
			}


		}


		imagePoints = imageWidth * imageHeight;

		//cout << "number of frames = " << numOfFrames << " Image width =  " << imageWidth << " image height = " << imageHeight << " image depth = " << imageDepth << "\n";

		if (imageDepth == 8) vinput8bit = std::vector<uint8_t>(imagePoints);
		else if (imageDepth == 16)vinput16bit = std::vector<uint16_t>(imagePoints);
		else if (imageDepth == 32)vinput32bit = std::vector<uint32_t>(imagePoints);
	}

	inline TiffInput::~TiffInput() {
		ifs.close();
	}

	inline void TiffInput::ReadIFDTag() {

		countofifd = read16bit();
		uint16_t ifdtag, datatype, datanum;
		uint32_t outputnum;
		for (uint16_t i = 0; i < countofifd; i++) {
			ifdtag = read16bit();
			datatype = read16bit();
			datanum = read32bit();

			if (datatype == 3) {
				outputnum = read16bit();
				read16bit();
			}
			else if (datatype == 1) {
				outputnum = read8bit();
				read8bit();
				read8bit();
				read8bit();
			}
			else outputnum = read32bit();

			if (ifdtag == 273) {
				stripoffset = outputnum;
				numofstrips = datanum;
				stripNumBytes = datatype;
			}
			else if (ifdtag == 278)rowsperstrip = outputnum;
			else if (ifdtag == 279) {
				bytecountoffset = outputnum;
				byteNumBytes = datatype;
			}

		}

	}

	inline void TiffInput::ReadBigIFDTag() {
		countofifd64 = read64bit();
		uint16_t ifdtag, datatype;
		uint64_t outputnum, datanum;
		for (uint16_t i = 0; i < countofifd64; i++) {
			ifdtag = read16bit();
			datatype = read16bit();
			datanum = read64bit();


			if (datatype == 3) {
				outputnum = read16bit();
				ifs.read((char*)&input64bit, 6);
			}
			else if (datatype == 1) {
				outputnum = read8bit();
				ifs.read((char*)&input64bit, 7);
			}
			else if (datatype > 15) {
				outputnum = read64bit();
			}
			else {
				outputnum = read32bit();
				read32bit();
			}

			if (ifdtag == 273) {
				stripoffset = outputnum;
				numofstrips = datanum;
				stripNumBytes = datatype;
			}
			else if (ifdtag == 278)rowsperstrip = outputnum;
			else if (ifdtag == 279) {
				bytecountoffset = outputnum;
				byteNumBytes = datatype;
			}
			//std::cout << "ifd tag " << ifdtag << " data type " << datatype << " number of entries " << datanum << " value " << outputnum << "\n";
		}


	}

	template <typename vectortype>
	inline void TiffInput::read1dImage(uint16_t framenumber, ::std::vector<vectortype>& imageout) {
		imageout.resize(imagePoints);

		if (bigtiff) {
			ifs.seekg(allfilepositions64[framenumber]);
			ReadBigIFDTag();
		}
		else {
			ifs.seekg(allfilepositions[framenumber]);
			ReadIFDTag();
		}
		
		if (numofstrips == 1) {
			
			ifs.seekg(stripoffset);
			if (imageDepth == 8) {
				read8bitimage();
				for (uint32_t i = 0; i < imagePoints; i++)imageout[i] = vinput8bit[i];
			}
			else if (imageDepth == 16) {
				read16bitimage();
				for (uint32_t i = 0; i < imagePoints; i++)imageout[i] = vinput16bit[i];
			}
			else if (imageDepth == 32) {
				read32bitimage();
				for (uint32_t i = 0; i < imagePoints; i++)imageout[i] = vinput32bit[i];
			}
			else std::invalid_argument("Error : This library only works on 8, 16 and 32 bit images. Image depth detected : " + std::to_string(imageDepth) + "\n");
		}
		else {

			std::vector<uint64_t> alloffsets(numofstrips, 0), numofpixelsinstrips(numofstrips, 0);
			ifs.seekg(stripoffset);
			for (uint32_t i = 0; i < numofstrips; i++)alloffsets[i] = readbit(stripNumBytes);
			//std::cout << "alloffsets[i] = " << alloffsets[0] << "\n";
			ifs.seekg(bytecountoffset);
			for (uint32_t i = 0; i < numofstrips; i++)numofpixelsinstrips[i] = readbit(byteNumBytes) * 8 / imageDepth;//number of pixels per strip
			uint32_t totpixelcount = 0;
			//std::cout << "numofpixelsinstrips[i] = " << numofpixelsinstrips[0] << "\n";


			for (uint32_t i = 0; i < numofstrips; i++) {
				ifs.seekg(alloffsets[i]);
				if (imageDepth == 8) {
					ifs.read((char*)vinput8bit.data(), numofpixelsinstrips[i]);
					for (uint32_t j = 0; j < numofpixelsinstrips[i]; j++) {
						imageout[totpixelcount] = vinput8bit[j];
						totpixelcount++;
					}
				}
				else if (imageDepth == 16) {
					ifs.read((char*)vinput16bit.data(), 2*numofpixelsinstrips[i]);
					//std::cout << "pixinstrip = " << numofpixelsinstrips[i] << "\n";
					for (uint32_t j = 0; j < numofpixelsinstrips[i]; j++) {
						if (bigendian) {
							imageout[totpixelcount] = (((vinput16bit[j] >> 8)) | (vinput16bit[j] << 8));
						}
						else imageout[totpixelcount] = vinput16bit[j];
						totpixelcount++;
					}
				}
				else if (imageDepth == 32) {
					ifs.read((char*)vinput32bit.data(), 4 * numofpixelsinstrips[i]);
					for (uint32_t j = 0; j < numofpixelsinstrips[i]; j++) {
						if (bigendian) {
							imageout[totpixelcount] = (((vinput32bit[j] & 0x000000FF) << 24) + ((vinput32bit[j] & 0x0000FF00) << 8) +
								((vinput32bit[j] & 0x00FF0000) >> 8) + ((vinput32bit[j] & 0xFF000000) >> 24));
						}
						else imageout[totpixelcount] = vinput32bit[j];
						totpixelcount++;
					}
				}	
			}
		}
	};


	template <typename vectortype>
	inline void TiffInput::read2dImage(uint16_t framenumber, std::vector<std::vector<vectortype> >& imageout) {
		imageout.resize(imageWidth);
		for (int i = 0; i < imageWidth; i++)imageout[i].resize(imageHeight);

		if (bigtiff) {
			ifs.seekg(allfilepositions64[framenumber]);
			ReadBigIFDTag();
		}
		else {
			ifs.seekg(allfilepositions[framenumber]);
			ReadIFDTag();
		}
		
		//std::cout << numofstrips << "\n";
		if (numofstrips == 1) {
			ifs.seekg(stripoffset);
			if (imageDepth == 8) {
				read8bitimage();
				for (uint32_t i = 0; i < imagePoints; i++)imageout[i%imageWidth][i / imageWidth] = vinput8bit[i];
			}
			else if (imageDepth == 16) {
				read16bitimage();
				for (uint32_t i = 0; i < imagePoints; i++)imageout[i%imageWidth][i / imageWidth] = vinput16bit[i];
			}
			else if (imageDepth == 32) {
				read32bitimage();
				for (uint32_t i = 0; i < imagePoints; i++)imageout[i%imageWidth][i / imageWidth] = vinput32bit[i];
			}
			else std::invalid_argument("Error : This library only works on 8, 16 and 32 bit images. Image depth detected : "+ std::to_string(imageDepth) + "\n");

		}
		else {
			std::vector<uint32_t> alloffsets(numofstrips, 0), numofpixelsinstrips(numofstrips, 0);
			ifs.seekg(stripoffset);
			for (uint32_t i = 0; i < numofstrips; i++)alloffsets[i] = readbit(stripNumBytes);
			//std::cout << "alloffsets[i] = " << alloffsets[0] << "\n";
			ifs.seekg(bytecountoffset);
			for (uint32_t i = 0; i < numofstrips; i++)numofpixelsinstrips[i] = readbit(byteNumBytes) * 8 / imageDepth;//number of pixels per strip
			uint32_t totpixelcount = 0;
			//std::cout << "numofpixelsinstrips[i] = " << numofpixelsinstrips[0] << "\n";

			totpixelcount = 0;
			for (uint32_t i = 0; i < numofstrips; i++) {
				ifs.seekg(alloffsets[i]);
				if (imageDepth == 8) {
					ifs.read((char*)vinput8bit.data(), numofpixelsinstrips[i]);
					for (uint32_t j = 0; j < numofpixelsinstrips[i]; j++) {
						imageout[totpixelcount%imageWidth][totpixelcount / imageWidth] = vinput8bit[j];
						totpixelcount++;
					}
				}
				else if (imageDepth == 16) {
					ifs.read((char*)vinput16bit.data(), 2 * numofpixelsinstrips[i]);
					for (uint32_t j = 0; j < numofpixelsinstrips[i]; j++) {
						if (bigendian) {
							imageout[totpixelcount%imageWidth][totpixelcount / imageWidth] = (((vinput16bit[j] >> 8)) | (vinput16bit[j] << 8));
						}
						else imageout[totpixelcount%imageWidth][totpixelcount / imageWidth] = vinput16bit[j];
						totpixelcount++;
					}
				}
				else if (imageDepth == 32) {
					ifs.read((char*)vinput32bit.data(), 4 * numofpixelsinstrips[i]);
					for (uint32_t j = 0; j < numofpixelsinstrips[i]; j++) {
						if (bigendian) {
							imageout[totpixelcount%imageWidth][totpixelcount / imageWidth] = (((vinput32bit[j] & 0x000000FF) << 24) + ((vinput32bit[j] & 0x0000FF00) << 8) +
								((vinput32bit[j] & 0x00FF0000) >> 8) + ((vinput32bit[j] & 0xFF000000) >> 24));
						}
						else imageout[totpixelcount%imageWidth][totpixelcount / imageWidth] = vinput32bit[j];
						totpixelcount++;
					}
				}
			}
		}
	}









	class TiffOutput {

		std::string filename;

		uint8_t output8bit;
		uint16_t output16bit;
		uint32_t output32bit;
		uint64_t output64bit;

		std::vector<uint8_t> voutput8bit;
		std::vector<uint16_t> voutput16bit;
		std::vector<uint32_t> voutput32bit;

		uint32_t previfdoffset;
		uint64_t previfdoffset64;

		uint32_t currentifdoffset;
		uint64_t currentifdoffset64;

		uint16_t countofifd;

		std::ofstream ofs;

		void writeifd(uint16_t ifdval, uint16_t variabletype, uint64_t value);

		void writeallifds();
		void writeallifds64();

	public:

		uint64_t filesize;
		uint32_t numOfFrames;
		uint32_t imageWidth;
		uint32_t imageHeight;
		uint32_t imageDepth;
		uint32_t imagePoints;
		bool bigTiff;



		TiffOutput(std::string filenamein, uint32_t imageWidth, uint32_t imageHeight, uint32_t imageDepth, bool bigTiffin = false);
		~TiffOutput();

		template <typename vectortype>
		void write1dImage(::std::vector<vectortype>& imageout);

		template <typename vectortype>
		void write2dImage(::std::vector< ::std::vector<vectortype> >& imageout);

	};

	inline TiffOutput::TiffOutput(std::string filenamein, uint32_t imageWidthin, uint32_t imageHeightin, uint32_t imageDepthin, bool bigTiffin) {
		filename = filenamein;

		imageWidth = imageWidthin;
		imageHeight = imageHeightin;
		imageDepth = imageDepthin;
		imagePoints = imageWidth * imageHeight;

		bigTiff = bigTiffin;

		ofs.open(filename, std::ofstream::binary | std::ofstream::out | std::ofstream::trunc);

		if (bigTiff) {
			output16bit = 18761;
			ofs.write((char*)&output16bit, 2);
			output16bit = 43;
			ofs.write((char*)&output16bit, 2);
			output16bit = 8;
			ofs.write((char*)&output16bit, 2);
			output16bit = 0;
			ofs.write((char*)&output16bit, 2);
			output64bit = 16;
			ofs.write((char*)&output64bit, 8);
		}
		else {
			output16bit = 18761;
			ofs.write((char*)&output16bit, 2);
			output16bit = 42;
			ofs.write((char*)&output16bit, 2);
			output32bit = 8;
			ofs.write((char*)&output32bit, 4);
		}
		previfdoffset = 0;
		previfdoffset64 = 0;
		countofifd = 10;

		if (imageDepth == 8) voutput8bit = std::vector<uint8_t>(imagePoints);
		else if (imageDepth == 16)voutput16bit = std::vector<uint16_t>(imagePoints);
		else if (imageDepth == 32)voutput32bit = std::vector<uint32_t>(imagePoints);
	}

	inline TiffOutput::~TiffOutput() {
		ofs.close();
	};

	inline void TiffOutput::writeifd(uint16_t ifdval, uint16_t variablebitdepth, uint64_t value) {

		output16bit = ifdval;
		ofs.write((char*)&output16bit, 2);

		if (variablebitdepth == 8)output16bit = 1;
		else if (variablebitdepth == 16)output16bit = 3;
		else if (variablebitdepth == 64)output16bit = 16;
		else output16bit = 4;

		ofs.write((char*)&output16bit, 2);

		if (bigTiff) {
			output64bit = 1;
			ofs.write((char*)&output64bit, 8);
		}
		else {
			output32bit = 1;
			ofs.write((char*)&output32bit, 4);

		}

		if (variablebitdepth == 8) {
			output8bit = value;
			ofs.write((char*)&output8bit, 1);
			output8bit = 0;
			int loopsToFill = 3;
			if (bigTiff) loopsToFill  = 7;
			for(int j=0;j<loopsToFill;j++)ofs.write((char*)&output8bit, 1);
		}
		else if (variablebitdepth == 16) {
			output16bit = value;
			ofs.write((char*)&output16bit, 2);
			output16bit = 0;
			int loopsToFill = 1;
			if (bigTiff) loopsToFill = 3;
			for (int j = 0; j < loopsToFill; j++)ofs.write((char*)&output16bit, 2);
		}
		else if (variablebitdepth == 64) {
			output64bit = value;
			ofs.write((char*)&output64bit, 8);
		}
		else {
			output32bit = value;
			ofs.write((char*)&output32bit, 4);
			if (bigTiff) {
				output32bit = 0;
				ofs.write((char*)&output32bit, 4);
			}
		}
	};

	inline void TiffOutput::writeallifds() {

		currentifdoffset = ofs.tellp();


		if (previfdoffset > 0) {
			ofs.seekp((previfdoffset + 2 + 12 * countofifd));
			ofs.write((char*)&currentifdoffset, 4);
			ofs.seekp(currentifdoffset);
		}

		output16bit = countofifd;
		ofs.write((char*)&output16bit, 2);

		writeifd(256, 32, imageWidth);
		writeifd(257, 32, imageHeight);
		writeifd(258, 16, imageDepth);
		writeifd(259, 16, 1);//Compression
		writeifd(262, 16, 1);//PhotometricInterpretation
		writeifd(273, 32, (currentifdoffset + 6 + 12 * countofifd));

		writeifd(277, 16, 1);//samplesperpixel
		writeifd(278, 32, imageHeight);
		writeifd(279, 32, imagePoints*imageDepth / 8);
		writeifd(284, 16, 1);//planar config

		output32bit = 0;
		ofs.write((char*)&output32bit, 4);

		previfdoffset = currentifdoffset;
	}


	inline void TiffOutput::writeallifds64() {

		currentifdoffset64 = ofs.tellp();

		if (previfdoffset64 > 0) {
			output64bit = (previfdoffset64 + 8 + 20 * (uint64_t)countofifd);
			ofs.seekp(output64bit);
			ofs.write((char*)&currentifdoffset64, 8);
			ofs.seekp(currentifdoffset64);
		}
		output64bit = countofifd;
		ofs.write((char*)&output64bit, 8);

		writeifd(256, 32, imageWidth);
		writeifd(257, 32, imageHeight);
		writeifd(258, 16, imageDepth);
		writeifd(259, 16, 1);//Compression
		writeifd(262, 16, 1);//PhotometricInterpretation
		output64bit = (currentifdoffset64 + 16 + 20 * (uint64_t)countofifd);
		writeifd(273, 64, output64bit);

		writeifd(277, 16, 1);//samplesperpixel
		writeifd(278, 32, imageHeight);
		writeifd(279, 32, imagePoints * imageDepth / 8);
		writeifd(284, 16, 1);//planar config

		output64bit = 0;
		ofs.write((char*)&output64bit, 8);

		previfdoffset64 = currentifdoffset64;
	}

	template <typename vectortype>
	inline void TiffOutput::write1dImage(::std::vector<vectortype>& imageout) {

		if(bigTiff)writeallifds64();
		else writeallifds();

		if (imageDepth == 8) {
			for (uint32_t i = 0; i < imagePoints; i++) voutput8bit[i] = imageout[i];
			ofs.write((char*)voutput8bit.data(), imagePoints);
		}
		else if (imageDepth == 16) {
			for (uint32_t i = 0; i < imagePoints; i++) voutput16bit[i] = imageout[i];
			ofs.write((char*)voutput16bit.data(), 2 * imagePoints);
		}
		else if (imageDepth == 32) {
			for (uint32_t i = 0; i < imagePoints; i++) voutput32bit[i] = imageout[i];
			ofs.write((char*)voutput32bit.data(), 4 * imagePoints);
		}
		else std::invalid_argument("Trying to write out in an unsupported bit depth. Only 8, 16 and 32 are supported with this library\n");

	}

	template <typename vectortype>
	inline void TiffOutput::write2dImage(::std::vector< ::std::vector<vectortype> >& imageout) {

		if (bigTiff)writeallifds64();
		else writeallifds();

		if (imageDepth == 8) {
			for (uint32_t i = 0; i < imagePoints; i++) voutput8bit[i] = imageout[i%imageWidth][i / imageWidth];
			ofs.write((char*)voutput8bit.data(), imagePoints);
		}
		else if (imageDepth == 16) {
			for (uint32_t i = 0; i < imagePoints; i++) voutput16bit[i] = imageout[i%imageWidth][i / imageWidth];
			ofs.write((char*)voutput16bit.data(), 2 * imagePoints);
		}
		else if (imageDepth == 32) {
			for (uint32_t i = 0; i < imagePoints; i++) voutput32bit[i] = imageout[i%imageWidth][i / imageWidth];
			ofs.write((char*)voutput32bit.data(), 4 * imagePoints);
		}
		else std::invalid_argument("Trying to write out in an unsupported bit depth. Only 8, 16 and 32 are supported with this library\n");

	}
}

#endif