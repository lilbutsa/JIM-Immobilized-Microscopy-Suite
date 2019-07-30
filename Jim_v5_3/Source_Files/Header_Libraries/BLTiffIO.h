#pragma once
#ifndef BLTiffIO_H
#define BLTiffIO_H

#include <stdint.h>
#include <string>
#include <iostream>
#include <fstream>
#include <vector>

namespace BLTiffIO {

	class TiffInput {

		std::string filename;

		uint8_t input8bit;
		uint16_t input16bit;
		uint32_t input32bit;

		std::vector<uint8_t> vinput8bit;
		std::vector<uint16_t> vinput16bit;
		std::vector<uint32_t> vinput32bit;

		bool bigendian;

		uint32_t currentoffset;

		uint16_t countofifd;

		std::vector<uint32_t> allfilepositions;

		std::ifstream ifs;

		void read8bitimage();
		void read16bitimage();
		void read32bitimage();

		uint8_t read8bit();
		uint16_t read16bit();
		uint32_t read32bit();

		void ReadIFDTag();
		uint32_t numofstrips, rowsperstrip, stripoffset, bytecountoffset;

	public:

		uint64_t filesize;
		uint32_t numOfFrames;
		uint32_t imageWidth;
		uint32_t imageHeight;
		uint32_t imageDepth;
		uint32_t imagePoints;



		TiffInput(std::string filenamein);
		~TiffInput();

		template <typename vectortype>
		void read1dImage(uint16_t framenumber, ::std::vector<vectortype>& imageout);

		template <typename vectortype>
		void read2dImage(uint16_t framenumber, ::std::vector<::std::vector<vectortype>>& imageout);

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

	inline void TiffInput::read8bitimage() {
		ifs.read((char*) vinput8bit.data(), imagePoints);
	}

	inline void TiffInput::read16bitimage() {
		ifs.read((char*)vinput16bit.data(), 2*imagePoints);

		if (bigendian) {
			for(uint32_t i=0;i<imagePoints;i++)vinput16bit[i] = (((vinput16bit[i] >> 8)) | (vinput16bit[i] << 8));
		}

	}

	inline void TiffInput::read32bitimage() {
		ifs.read((char*)vinput32bit.data(), 4 * imagePoints);

		if (bigendian) {
			for (uint32_t i = 0; i<imagePoints; i++)vinput32bit[i] = (((vinput32bit[i] & 0x000000FF) << 24) + ((vinput32bit[i] & 0x0000FF00) << 8) +
				((vinput32bit[i] & 0x00FF0000) >> 8) + ((vinput32bit[i] & 0xFF000000) >> 24));
		}

	}

	inline TiffInput::TiffInput(std::string filenamein) {
		filename = filenamein;


		ifs.open(filename, std::ifstream::ate | std::ifstream::binary);
		if (ifs.is_open() == false) {
			std::cout << "Error:could not open file!\n";
			return;
		}

		filesize = ifs.tellg();
		ifs.close();

		ifs.open(filename, std::ifstream::binary);

		ifs.read((char*)&input16bit, 2);
		if (input16bit == 19789)bigendian = true;
		else if (input16bit == 18761)bigendian = false;
		else std::cout << "error reading which endian the file is!\n";

		read16bit();
		currentoffset = read32bit();
		//cout << "file size " << filesize << " bigtiff " << currentoffset << "\n";


		while (currentoffset > 0) {

			allfilepositions.push_back(currentoffset);

			ifs.seekg(currentoffset);

			countofifd = read16bit();

			currentoffset += 2 + 12 * countofifd;

			ifs.seekg(currentoffset);
			currentoffset = read32bit();

		}

		numOfFrames = allfilepositions.size();



		ifs.seekg(allfilepositions[0]);
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

			if (ifdtag == 256)imageWidth = outputnum;
			else if (ifdtag == 257)imageHeight = outputnum;
			else if (ifdtag == 258)imageDepth = outputnum;
			//std::cout << "ifd tag " << ifdtag << " data type " << datatype << " number of entries " << datanum << " value " << outputnum << "\n";

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
			}
			else if (ifdtag == 278)rowsperstrip = outputnum;
			else if (ifdtag == 279)bytecountoffset = outputnum;

		}

	}

	template <typename vectortype>
	inline void TiffInput::read1dImage(uint16_t framenumber, ::std::vector<vectortype>& imageout) {
		imageout.resize(imagePoints);
		ifs.seekg(allfilepositions[framenumber]);

		ReadIFDTag();

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
			else cout << "Error : This library only works on 8, 16 and 32 bit images. Image depth detected : " << imageDepth << "\n";
		}
		else {

			vector<uint32_t> alloffsets(numofstrips, 0), numofpixelsinstrips(numofstrips, 0);
			ifs.seekg(stripoffset);
			for (uint32_t i = 0; i < numofstrips; i++)alloffsets[i] = read32bit();
			ifs.seekg(bytecountoffset);
			for (uint32_t i = 0; i < numofstrips; i++)numofpixelsinstrips[i] = read32bit() * 8 / imageDepth;//number of pixels per strip
			uint32_t totpixelcount = 0;

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
							imageout[totpixelcount] == (((vinput32bit[j] & 0x000000FF) << 24) + ((vinput32bit[j] & 0x0000FF00) << 8) +
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
	inline void TiffInput::read2dImage(uint16_t framenumber, std::vector<std::vector<vectortype>>& imageout) {
		imageout.resize(imageWidth);
		for (int i = 0; i < imageWidth; i++)imageout[i].resize(imageHeight);


		ifs.seekg(allfilepositions[framenumber]);

		ReadIFDTag();

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
			else cout << "Error : This library only works on 8, 16 and 32 bit images. Image depth detected : " << imageDepth << "\n";

		}
		else {
			std::vector<uint32_t> alloffsets(numofstrips, 0), numofpixelsinstrips(numofstrips, 0);
			ifs.seekg(stripoffset);
			for (uint32_t i = 0; i < numofstrips; i++)alloffsets[i] = read32bit();
			ifs.seekg(bytecountoffset);
			for (uint32_t i = 0; i < numofstrips; i++)numofpixelsinstrips[i] = read32bit() * 8 / imageDepth;//number of pixels per strip
			uint32_t totpixelcount = 0;
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
							imageout[totpixelcount%imageWidth][totpixelcount / imageWidth] == (((vinput32bit[j] & 0x000000FF) << 24) + ((vinput32bit[j] & 0x0000FF00) << 8) +
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

		std::vector<uint8_t> voutput8bit;
		std::vector<uint16_t> voutput16bit;
		std::vector<uint32_t> voutput32bit;

		uint32_t previfdoffset;

		uint32_t currentifdoffset;

		uint16_t countofifd;

		std::ofstream ofs;

		void writeifd(uint16_t ifdval, uint16_t variabletype, uint32_t value);

		void writeallifds();

	public:

		uint64_t filesize;
		uint32_t numOfFrames;
		uint32_t imageWidth;
		uint32_t imageHeight;
		uint32_t imageDepth;
		uint32_t imagePoints;



		TiffOutput(std::string filenamein, uint32_t imageWidth, uint32_t imageHeight, uint32_t imageDepth);
		~TiffOutput();

		template <typename vectortype>
		void write1dImage(::std::vector<vectortype>& imageout);

		template <typename vectortype>
		void write2dImage(::std::vector<::std::vector<vectortype>>& imageout);

	};

	inline TiffOutput::TiffOutput(std::string filenamein, uint32_t imageWidthin, uint32_t imageHeightin, uint32_t imageDepthin) {
		filename = filenamein;

		imageWidth = imageWidthin;
		imageHeight = imageHeightin;
		imageDepth = imageDepthin;
		imagePoints = imageWidth * imageHeight;



		ofs.open(filename, std::ofstream::binary | std::ofstream::out | std::ofstream::trunc);

		//cout << "file is open " << ofs.is_open() << "\n";

		output16bit = 18761;
		ofs.write((char*)&output16bit, 2);
		output16bit = 42;
		ofs.write((char*)&output16bit, 2);
		output32bit = 8;
		ofs.write((char*)&output32bit, 4);

		previfdoffset = 0;
		countofifd = 10;

		if (imageDepth == 8) voutput8bit = std::vector<uint8_t>(imagePoints);
		else if (imageDepth == 16)voutput16bit = std::vector<uint16_t>(imagePoints);
		else if (imageDepth == 32)voutput32bit = std::vector<uint32_t>(imagePoints);
	}

	inline TiffOutput::~TiffOutput() {
		ofs.close();
	};

	inline void TiffOutput::writeifd(uint16_t ifdval, uint16_t variablebitdepth, uint32_t value) {

		output16bit = ifdval;
		ofs.write((char*)&output16bit, 2);

		if (variablebitdepth == 8)output16bit = 1;
		else if (variablebitdepth == 16)output16bit = 3;
		else output16bit = 4;

		ofs.write((char*)&output16bit, 2);

		output32bit = 1;
		ofs.write((char*)&output32bit, 4);

		if (variablebitdepth == 8) {
			output8bit = value;
			ofs.write((char*)&output8bit, 1);
			output8bit = 0;
			ofs.write((char*)&output8bit, 1);
			ofs.write((char*)&output8bit, 1);
			ofs.write((char*)&output8bit, 1);
		}
		else if (variablebitdepth == 16) {
			output16bit = value;
			ofs.write((char*)&output16bit, 2);
			output16bit = 0;
			ofs.write((char*)&output16bit, 2);
		}
		else {
			output32bit = value;
			ofs.write((char*)&output32bit, 4);
		}
	};

	inline void TiffOutput::writeallifds() {

		currentifdoffset = ofs.tellp();


		if (previfdoffset > 0) {
			ofs.seekp(previfdoffset + 2 + 12 * countofifd);
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
		writeifd(273, 32, currentifdoffset + 6 + 12 * countofifd);

		writeifd(277, 16, 1);//samplesperpixel
		writeifd(278, 32, imageHeight);
		writeifd(279, 32, imagePoints*imageDepth / 8);
		writeifd(284, 16, 1);//planar config

		output32bit = 0;
		ofs.write((char*)&output32bit, 4);

		previfdoffset = currentifdoffset;
	}

	template <typename vectortype>
	inline void TiffOutput::write1dImage(::std::vector<vectortype>& imageout) {

		writeallifds();

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
		else std::cout << "Trying to write out in an unsupported bit depth. Only 8, 16 and 32 are supported with this library\n";

	}

	template <typename vectortype>
	inline void TiffOutput::write2dImage(::std::vector<::std::vector<vectortype>>& imageout) {

		writeallifds();

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
		else std::cout << "Trying to write out in an unsupported bit depth. Only 8, 16 and 32 are supported with this library\n";

	}
}

#endif