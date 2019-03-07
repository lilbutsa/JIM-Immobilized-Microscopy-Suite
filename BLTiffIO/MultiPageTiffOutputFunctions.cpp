#include "stdafx.h"
#include "BLTiffIO.h"
#include <algorithm>

BLTiffIO::MultiPageTiffOutput::MultiPageTiffOutput(std::string outputfile, int numberOfFrames, int imageDepth, int imageWidth, int imageHeight) {

	depth = imageDepth;
	height = imageHeight;
	width = imageWidth;
	numofframe = numberOfFrames;

	TIFFSetWarningHandler(NULL);

	std::string outputstr = outputfile;

	output_tiff = TIFFOpen(outputstr.c_str(), "w");


	TIFFSetField(output_tiff, TIFFTAG_IMAGELENGTH, imageHeight);
	TIFFSetField(output_tiff, TIFFTAG_IMAGEWIDTH, imageWidth);

	TIFFSetField(output_tiff, TIFFTAG_SAMPLESPERPIXEL, 1);
	TIFFSetField(output_tiff, TIFFTAG_BITSPERSAMPLE, imageDepth);
	TIFFSetField(output_tiff, TIFFTAG_PLANARCONFIG, PLANARCONFIG_CONTIG);
	TIFFSetField(output_tiff, TIFFTAG_ORIENTATION, ORIENTATION_TOPLEFT);
	TIFFSetField(output_tiff, TIFFTAG_PHOTOMETRIC, PHOTOMETRIC_MINISBLACK);
	TIFFSetField(output_tiff, TIFFTAG_ROWSPERSTRIP, TIFFDefaultStripSize(output_tiff, 0));
	TIFFSetField(output_tiff, TIFFTAG_RESOLUTIONUNIT, 2);

	TIFFSetField(output_tiff, TIFFTAG_SUBFILETYPE, FILETYPE_PAGE);
	//TIFFSetField(output_tiff, TIFFTAG_PAGENUMBER, 0, numberOfFrames);

	if (depth == 8) {
		firstpagebuffer = _TIFFmalloc(sizeof(uint8)*imageWidth);
		for (int i = 0; i < imageWidth; i++)((uint8*)firstpagebuffer)[i] = 0;
	}
	else if (depth == 32) {
		firstpagebuffer = _TIFFmalloc(sizeof(uint32)*imageWidth);
		for (int i = 0; i < imageWidth; i++)((uint32*)firstpagebuffer)[i] = 0;
	}
	else {
		firstpagebuffer = _TIFFmalloc(sizeof(uint16)*imageWidth);
		for (int i = 0; i < imageWidth; i++)((uint16*)firstpagebuffer)[i] = 0;
	}

}

BLTiffIO::MultiPageTiffOutput::~MultiPageTiffOutput() {

	if(firstpagebuffer)_TIFFfree(firstpagebuffer);
	if(output_tiff)TIFFClose(output_tiff);

}


int BLTiffIO::MultiPageTiffOutput::totalNumberofFrames() {
	return numofframe;
}

int BLTiffIO::MultiPageTiffOutput::imageBitDepth() {
	return depth;
}

int BLTiffIO::MultiPageTiffOutput::imageWidth() {
	return width;
}

int BLTiffIO::MultiPageTiffOutput::imageHeight() {
	return height;
}


template <typename outputvectortype>
int WriteImage2dFunc(int framenum, std::vector<std::vector<outputvectortype>>& imageout, int height, int width, int depth,int numofframe, TIFF* output_tiff, tdata_t firstpagebuffer) {


	if (framenum >= numofframe)return 1;
	TIFFSetField(output_tiff, TIFFTAG_IMAGELENGTH, height);
	TIFFSetField(output_tiff, TIFFTAG_IMAGEWIDTH, width);

	TIFFSetField(output_tiff, TIFFTAG_SAMPLESPERPIXEL, 1);
	TIFFSetField(output_tiff, TIFFTAG_BITSPERSAMPLE, depth);
	TIFFSetField(output_tiff, TIFFTAG_PLANARCONFIG, PLANARCONFIG_CONTIG);
	TIFFSetField(output_tiff, TIFFTAG_ORIENTATION, ORIENTATION_TOPLEFT);
	TIFFSetField(output_tiff, TIFFTAG_PHOTOMETRIC, PHOTOMETRIC_MINISBLACK);
	TIFFSetField(output_tiff, TIFFTAG_ROWSPERSTRIP, TIFFDefaultStripSize(output_tiff, 0));
	TIFFSetField(output_tiff, TIFFTAG_RESOLUTIONUNIT, 2);

	TIFFSetField(output_tiff, TIFFTAG_SUBFILETYPE, FILETYPE_PAGE);
	TIFFSetField(output_tiff, TIFFTAG_PAGENUMBER, framenum, numofframe);
	TIFFSetDirectory(output_tiff, framenum);

	if (depth == 8) {
		for (int j = 0; j < height; ++j) {
			for (int i = 0; i < width; i++)((uint8*)firstpagebuffer)[i] =std::max(std::min((long)imageout[i][j],(long)255),(long)0);
			TIFFWriteScanline(output_tiff, firstpagebuffer, j);
		}
	}
	else if (depth == 32) {
		for (int j = 0; j < height; ++j) {
			for (int i = 0; i < width; i++)((uint32*)firstpagebuffer)[i]=std::max(std::min((long) imageout[i][j], (long)4294967295),(long)0);
			TIFFWriteScanline(output_tiff, firstpagebuffer, j);
		}
	}
	else {
		for (int j = 0; j < height; ++j) {
			for (int i = 0; i < width; i++)((uint16*)firstpagebuffer)[i]= std::max(std::min((long) imageout[i][j], (long) 65535),(long) 0);
			TIFFWriteScanline(output_tiff, firstpagebuffer, j);
		}
	}
	TIFFWriteDirectory(output_tiff);

	return 0;
}

void BLTiffIO::MultiPageTiffOutput::WriteImage2d(int framenum, std::vector<std::vector<double>>& imageout)
{
	WriteImage2dFunc(framenum, imageout, height, width, depth, numofframe,  output_tiff, firstpagebuffer);
}

void BLTiffIO::MultiPageTiffOutput::WriteImage2d(int framenum, std::vector<std::vector<float>>& imageout)
{
	WriteImage2dFunc(framenum, imageout, height, width, depth, numofframe, output_tiff, firstpagebuffer);
}

void BLTiffIO::MultiPageTiffOutput::WriteImage2d(int framenum, std::vector<std::vector<int>>& imageout)
{
	WriteImage2dFunc(framenum, imageout, height, width, depth, numofframe, output_tiff, firstpagebuffer);
}

void BLTiffIO::MultiPageTiffOutput::WriteImage2d(int framenum, std::vector<std::vector<long>>& imageout)
{
	WriteImage2dFunc(framenum, imageout, height, width, depth, numofframe, output_tiff, firstpagebuffer);
}

void BLTiffIO::MultiPageTiffOutput::WriteImage2d(int framenum, std::vector<std::vector<uint8_t>>& imageout)
{
	WriteImage2dFunc(framenum, imageout, height, width, depth, numofframe, output_tiff, firstpagebuffer);
}

void BLTiffIO::MultiPageTiffOutput::WriteImage2d(int framenum, std::vector<std::vector<uint16_t>>& imageout)
{
	WriteImage2dFunc(framenum, imageout, height, width, depth, numofframe, output_tiff, firstpagebuffer);
}

template <typename outputvectortype>
int WriteImage1dFunc(int framenum, std::vector<outputvectortype>& imageout, int height, int width, int depth, int numofframe, TIFF* output_tiff, tdata_t firstpagebuffer) {

	if (framenum >= numofframe)return 1;

	TIFFSetField(output_tiff, TIFFTAG_IMAGELENGTH, height);
	TIFFSetField(output_tiff, TIFFTAG_IMAGEWIDTH, width);

	TIFFSetField(output_tiff, TIFFTAG_SAMPLESPERPIXEL, 1);
	TIFFSetField(output_tiff, TIFFTAG_BITSPERSAMPLE, depth);
	TIFFSetField(output_tiff, TIFFTAG_PLANARCONFIG, PLANARCONFIG_CONTIG);
	TIFFSetField(output_tiff, TIFFTAG_ORIENTATION, ORIENTATION_TOPLEFT);
	TIFFSetField(output_tiff, TIFFTAG_PHOTOMETRIC, PHOTOMETRIC_MINISBLACK);
	TIFFSetField(output_tiff, TIFFTAG_ROWSPERSTRIP, TIFFDefaultStripSize(output_tiff, 0));
	TIFFSetField(output_tiff, TIFFTAG_RESOLUTIONUNIT, 2);

	TIFFSetField(output_tiff, TIFFTAG_SUBFILETYPE, FILETYPE_PAGE);
	TIFFSetField(output_tiff, TIFFTAG_PAGENUMBER, framenum, numofframe);
	TIFFSetDirectory(output_tiff, framenum);

	if (depth == 8) {
		for (int j = 0; j < height; ++j) {
			for (int i = 0; i < width; i++)((uint8*)firstpagebuffer)[i] = std::max(std::min((long)imageout[i + j*width], (long)255), (long)0);
			TIFFWriteScanline(output_tiff, firstpagebuffer, j);
		}
	}
	else if (depth == 32) {
		for (int j = 0; j < height; ++j) {
			for (int i = 0; i < width; i++) ((uint32*)firstpagebuffer)[i] = std::max(std::min((long)imageout[i + j*width], (long)4294967295), (long)0);
			TIFFWriteScanline(output_tiff, firstpagebuffer, j);
		}
	}
	else {
		for (int j = 0; j < height; ++j) {
			for (int i = 0; i < width; i++) ((uint16*)firstpagebuffer)[i] = std::max(std::min((long)imageout[i + j*width], (long)65535), (long)0);
			TIFFWriteScanline(output_tiff, firstpagebuffer, j);
		}
	}

	TIFFWriteDirectory(output_tiff);

	return 0;
}

void BLTiffIO::MultiPageTiffOutput::WriteImage1d(int framenum, std::vector<double>& imageout)
{
	WriteImage1dFunc(framenum, imageout, height, width, depth, numofframe, output_tiff, firstpagebuffer);
}

void BLTiffIO::MultiPageTiffOutput::WriteImage1d(int framenum, std::vector<float>& imageout)
{
	WriteImage1dFunc(framenum, imageout, height, width, depth, numofframe, output_tiff, firstpagebuffer);
}

void BLTiffIO::MultiPageTiffOutput::WriteImage1d(int framenum, std::vector<int>& imageout)
{
	WriteImage1dFunc(framenum, imageout, height, width, depth, numofframe, output_tiff, firstpagebuffer);
}

void BLTiffIO::MultiPageTiffOutput::WriteImage1d(int framenum, std::vector<long>& imageout)
{
	WriteImage1dFunc(framenum, imageout, height, width, depth, numofframe, output_tiff, firstpagebuffer);
}

void BLTiffIO::MultiPageTiffOutput::WriteImage1d(int framenum, std::vector<uint8_t>& imageout)
{
	WriteImage1dFunc(framenum, imageout, height, width, depth, numofframe, output_tiff, firstpagebuffer);
}

void BLTiffIO::MultiPageTiffOutput::WriteImage1d(int framenum, std::vector<uint16_t>& imageout)
{
	WriteImage1dFunc(framenum, imageout, height, width, depth, numofframe, output_tiff, firstpagebuffer);
}






//}